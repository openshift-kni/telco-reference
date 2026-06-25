#!/usr/bin/env python3
"""
Extract OpenAPI merge schemas from Kubernetes CRDs for ACM PolicyGenerator.

Downloads CRDs from GitHub or a cluster, extracts property schemas, and injects
strategic merge patch directives to produce schema.openapi files compatible with
ACM PolicyGenerator's openapi directive.

Most CRDs do not include x-kubernetes-list-type/x-kubernetes-list-map-keys
annotations, so merge keys are specified in the config file based on domain
knowledge of each CR's API. When a CRD does include these annotations, the
script auto-detects them.

Usage:
    # Generate schema for a specific component
    ./extract-schema.py --config hack/crd-schema-config.json --component ran -o schema.openapi

    # Generate schema for all CRDs in the config
    ./extract-schema.py --config hack/crd-schema-config.json -o schema.openapi

    # Quick test with a single CRD from a cluster
    oc get crd ptpconfigs.ptp.openshift.io -o json > /tmp/crd.json
    ./extract-schema.py --from-file /tmp/crd.json

    # Pipe from GitHub via yq
    curl -sL https://raw.githubusercontent.com/.../crd.yaml | yq -o json \\
        | ./extract-schema.py --from-file -
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error


# Annotations to strip from CRD schemas (converted or irrelevant for PolicyGenerator)
_STRIP_KEYS = frozenset({
    "x-kubernetes-list-type",
    "x-kubernetes-list-map-keys",
    "x-kubernetes-validations",
    "x-kubernetes-map-type",
})


def load_crd_from_file(path):
    """Load CRD(s) from a JSON file. Use '-' for stdin."""
    if path == "-":
        data = json.load(sys.stdin)
    else:
        with open(path) as f:
            data = json.load(f)

    if data.get("kind") == "CustomResourceDefinitionList":
        return data.get("items", [])
    if data.get("kind") == "CustomResourceDefinition":
        return [data]
    raise ValueError(f"Expected CustomResourceDefinition, got {data.get('kind')}")


def load_crd_from_cluster(crd_name):
    """Fetch a CRD from a running cluster via oc/kubectl."""
    for tool in ("oc", "kubectl"):
        try:
            result = subprocess.run(
                [tool, "get", "crd", crd_name, "-o", "json"],
                capture_output=True, text=True, check=True
            )
            return [json.loads(result.stdout)]
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    raise RuntimeError(f"Could not fetch CRD {crd_name} (tried oc and kubectl)")


def fetch_github_crd(owner, repo, ref, path):
    """Fetch a CRD from GitHub, converting YAML to JSON via yq if needed."""
    raw_url = f"https://raw.githubusercontent.com/{owner}/{repo}/{ref}/{path}"
    req = urllib.request.Request(raw_url)
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"token {token}")

    try:
        resp = urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        url = f"https://github.com/{owner}/{repo}/tree/{ref}"
        raise RuntimeError(
            f"Failed to download CRD from {owner}/{repo}@{ref} (HTTP {e.code}).\n"
            f"    Path: {path}\n"
            f"    Verify the ref exists: {url}"
        ) from None

    with resp:
        content = resp.read()

    # Try JSON first
    try:
        data = json.loads(content)
        if data.get("kind") == "CustomResourceDefinition":
            return [data]
    except (json.JSONDecodeError, AttributeError):
        pass

    # YAML — convert via yq
    try:
        result = subprocess.run(
            ["yq", "-o", "json"],
            input=content, capture_output=True, check=True
        )
        data = json.loads(result.stdout)
        if data.get("kind") == "CustomResourceDefinition":
            return [data]
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    raise RuntimeError(
        f"Could not parse {raw_url}. Install yq (https://github.com/mikefarah/yq) "
        f"for YAML conversion, or provide JSON input."
    )


def make_type_name(group, version, kind):
    """Convert API group/version/kind to schema.openapi type name.

    Reverses the DNS-style group, appends version and kind:
        ptp.openshift.io / v1 / PtpConfig  ->  io.openshift.ptp.v1.PtpConfig
    """
    reversed_group = ".".join(reversed(group.split(".")))
    return f"{reversed_group}.{version}.{kind}"


def resolve_path(schema, path_parts):
    """Walk into a schema following a dotted path like 'spec.profile.items.match'.

    Automatically descends into 'properties' at each object level and 'items'
    for arrays, so the path can use just the field names:
        'spec.profile'           -> properties.spec.properties.profile
        'spec.recommend.match'   -> properties.spec.properties.recommend.items.properties.match
    """
    node = schema
    for part in path_parts:
        # Try direct key first (for explicit 'items' in path)
        if part in node:
            node = node[part]
            continue
        # Descend into properties
        if "properties" in node and part in node["properties"]:
            node = node["properties"][part]
            continue
        # Descend through items.properties for arrays
        if "items" in node:
            items = node["items"]
            if "properties" in items and part in items["properties"]:
                node = items["properties"][part]
                continue
        raise KeyError(f"Cannot resolve path segment '{part}' in schema")
    return node


def convert_schema(schema):
    """Convert CRD schema to schema.openapi format.

    Strips CRD-specific annotations. If the CRD happens to include
    x-kubernetes-list-type: map annotations, converts them to the
    x-kubernetes-patch-* equivalents automatically.
    """
    if not isinstance(schema, dict):
        return schema

    is_map_list = schema.get("x-kubernetes-list-type") == "map"
    map_keys = schema.get("x-kubernetes-list-map-keys", [])

    result = {}
    for key, value in schema.items():
        if key in _STRIP_KEYS:
            continue
        if isinstance(value, dict):
            result[key] = convert_schema(value)
        elif isinstance(value, list):
            result[key] = [
                convert_schema(item) if isinstance(item, dict) else item
                for item in value
            ]
        else:
            result[key] = value

    # Auto-detected merge keys from CRD annotations
    if is_map_list and map_keys:
        result["x-kubernetes-patch-merge-key"] = (
            map_keys[0] if len(map_keys) == 1 else ",".join(map_keys)
        )
        result["x-kubernetes-patch-strategy"] = "merge"

    return result


def inject_merge_keys(schema, merge_keys):
    """Inject x-kubernetes-patch-* directives at specified paths.

    merge_keys is a dict mapping dotted paths to merge key field names:
        {"spec.profile": "name", "spec.recommend": "profile"}
    """
    for path, merge_key in merge_keys.items():
        parts = path.split(".")
        try:
            node = resolve_path(schema, parts)
        except KeyError as e:
            print(f"  WARNING: merge key path '{path}' not found: {e}", file=sys.stderr)
            continue

        if node.get("type") != "array":
            print(f"  WARNING: '{path}' is not an array, skipping merge key", file=sys.stderr)
            continue

        node["x-kubernetes-patch-merge-key"] = merge_key
        node["x-kubernetes-patch-strategy"] = "merge"


def prune_schema(schema):
    """Prune a schema to only the minimal structure needed for merge directives.

    For merge-annotated arrays, keeps only the type and merge directives — no
    item properties. If a merge-annotated array contains nested arrays that
    also have merge directives, those are kept as well.

    Example output for a merge-annotated array:
        {"type": "array", "x-kubernetes-patch-merge-key": "name",
         "x-kubernetes-patch-strategy": "merge"}
    """
    if not isinstance(schema, dict):
        return None

    # If this node has merge directives, keep it minimally
    if "x-kubernetes-patch-strategy" in schema:
        result = {
            "type": schema.get("type", "array"),
            "x-kubernetes-patch-strategy": schema["x-kubernetes-patch-strategy"],
        }
        if "x-kubernetes-patch-merge-key" in schema:
            result["x-kubernetes-patch-merge-key"] = schema["x-kubernetes-patch-merge-key"]
        # Check for nested merge-annotated arrays inside items
        if "items" in schema:
            nested = prune_schema(schema["items"])
            if nested is not None:
                result["items"] = nested
        return result

    pruned = {}

    # Recurse into properties
    if "properties" in schema:
        pruned_props = {}
        for prop_name, prop_schema in schema["properties"].items():
            result = prune_schema(prop_schema)
            if result is not None:
                pruned_props[prop_name] = result
        if pruned_props:
            pruned["properties"] = pruned_props
            if "type" in schema:
                pruned["type"] = schema["type"]

    # Recurse into items (for arrays without merge directives but with
    # nested merge-annotated children)
    if "items" in schema:
        result = prune_schema(schema["items"])
        if result is not None:
            pruned["items"] = result
            if "type" in schema:
                pruned["type"] = schema["type"]

    if not pruned:
        return None
    return pruned


def extract_crd_schema(crd, merge_keys=None, preferred_version=None):
    """Extract a schema.openapi definition from a CRD.

    Args:
        crd: Parsed CRD dict
        merge_keys: Optional dict of path -> merge_key to inject
        preferred_version: Optional API version to use (e.g. "v2"). If not
            specified, uses the storage version or first served version.

    Returns (type_name, schema) or (None, None).
    """
    group = crd["spec"]["group"]
    kind = crd["spec"]["names"]["kind"]
    versions = crd["spec"].get("versions", [])

    # If a preferred version is specified, try it first
    if preferred_version:
        matching = [v for v in versions if v["name"] == preferred_version]
        if matching:
            versions = matching + [v for v in versions if v["name"] != preferred_version]

    # Use the first version with a schema
    for v in versions:
        openapi_schema = v.get("schema", {}).get("openAPIV3Schema")
        if not openapi_schema:
            continue

        converted = convert_schema(openapi_schema)

        # Inject manually-specified merge keys
        if merge_keys:
            inject_merge_keys(converted, merge_keys)

        # Prune to only keep subtrees with merge directives
        pruned = prune_schema(converted)
        if pruned is None:
            continue

        pruned["type"] = "object"
        pruned["x-kubernetes-group-version-kind"] = [{
            "group": group,
            "kind": kind,
            "version": v["name"],
        }]

        type_name = make_type_name(group, v["name"], kind)
        return type_name, pruned

    return None, None


def process_config(config_path, component=None):
    """Process a JSON config file.

    Config format:
    {
      "crds": [
        {
          "name": "PtpConfig",
          "source": {
            "github": {
              "owner": "openshift",
              "repo": "ptp-operator",
              "ref": "release-4.22",
              "path": "config/crd/bases/ptp.openshift.io_ptpconfigs.yaml"
            }
          },
          "merge_keys": {
            "spec.profile": "name",
            "spec.recommend": "profile",
            "status.matchList": "nodeName"
          }
        },
        {
          "name": "PerformanceProfile",
          "version": "v2",
          "source": { "github": { "...": "..." } },
          "merge_keys": { "spec.hugepages.pages": "size" }
        }
      ]
    }

    Fields:
      name: Human-readable label for log output.
      version: Preferred API version to extract (e.g. "v2"). If omitted,
               uses the first version with a schema.
      source: One of "github", "cluster", or "file".
      merge_keys: Maps dotted field paths to merge key field names.
                  Most CRDs lack x-kubernetes-list-type annotations, so
                  merge keys must be specified explicitly based on domain
                  knowledge of each CR's API.

    Source types: "github", "cluster", "file".
    merge_keys: maps dotted field paths to the merge key field name.
    components: list of component names this CRD belongs to (e.g. ["ran", "core"]).
                Use --component to filter.
    """
    with open(config_path) as f:
        config = json.load(f)

    definitions = {}

    for entry in config.get("crds", []):
        # Filter by component if specified
        if component:
            entry_components = entry.get("components", [])
            if component not in entry_components:
                continue
        source = entry.get("source", {})
        name = entry.get("name", "unknown")
        merge_keys = entry.get("merge_keys", {})
        preferred_version = entry.get("version")

        try:
            crds = _load_crds(source, name)

            for crd in crds:
                type_name, schema = extract_crd_schema(crd, merge_keys, preferred_version)
                if type_name and schema:
                    definitions[type_name] = schema
                    print(f"  + {type_name}", file=sys.stderr)
                else:
                    crd_kind = crd.get("spec", {}).get("names", {}).get("kind", "?")
                    print(f"  - {crd_kind}: no schema found, skipping", file=sys.stderr)

        except RuntimeError as e:
            print(f"  ERROR: {e}", file=sys.stderr)
            sys.exit(1)

    return definitions


def _load_crds(source, name):
    """Load CRDs from the configured source."""
    if "github" in source:
        gh = source["github"]
        print(f"Downloading {name} from {gh['owner']}/{gh['repo']}@{gh['ref']}...",
              file=sys.stderr)
        return fetch_github_crd(gh["owner"], gh["repo"], gh["ref"], gh["path"])
    elif "file" in source:
        print(f"Loading {name} from {source['file']}...", file=sys.stderr)
        return load_crd_from_file(source["file"])
    elif "cluster" in source:
        print(f"Fetching {name} from cluster ({source['cluster']})...", file=sys.stderr)
        return load_crd_from_cluster(source["cluster"])
    else:
        raise ValueError(f"No source configured for {name}")


def main():
    parser = argparse.ArgumentParser(
        description="Extract OpenAPI merge schemas from CRDs for ACM PolicyGenerator"
    )

    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--config",
                        help="JSON config file listing CRDs, sources, and merge keys")
    source.add_argument("--from-file",
                        help="Local CRD JSON file (use '-' for stdin)")
    source.add_argument("--from-cluster",
                        help="CRD resource name to fetch from cluster")

    parser.add_argument("--output", "-o", help="Output file (default: stdout)")
    parser.add_argument("--component",
                        help="Only include CRDs tagged for this component (e.g. ran, core, hub)")

    args = parser.parse_args()

    definitions = {}

    if args.config:
        definitions.update(process_config(args.config, component=args.component))
    elif args.from_file:
        for crd in load_crd_from_file(args.from_file):
            type_name, schema = extract_crd_schema(crd)
            if type_name:
                definitions[type_name] = schema
                print(f"  + {type_name}", file=sys.stderr)
    elif args.from_cluster:
        for crd in load_crd_from_cluster(args.from_cluster):
            type_name, schema = extract_crd_schema(crd)
            if type_name:
                definitions[type_name] = schema
                print(f"  + {type_name}", file=sys.stderr)

    if not definitions:
        print("ERROR: No schemas extracted from any CRD", file=sys.stderr)
        sys.exit(1)

    # Sort for stable, diffable output
    sorted_defs = dict(sorted(definitions.items()))
    output = json.dumps({"definitions": sorted_defs}, indent=2) + "\n"

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"\nWrote {args.output} ({len(definitions)} definitions)", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
