#!/usr/bin/env python3
"""
Update hack/crd-schema-config.json with current Subscription channels,
components, and git refs by scanning the repository.

The JSON config is the single source of truth for the static CRD mapping
(owner, repo, path, merge_keys). This script only updates the dynamic fields:
  - subscription_channel: from Subscription CRs in the repo
  - components: which components (ran/core) have a Subscription for the operator
  - source.github.ref: derived from channel + OCP version conventions

Usage:
    python3 hack/generate-schema-config.py          # update in-place
    python3 hack/generate-schema-config.py --dry-run # preview changes
"""

import argparse
import json
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = REPO_ROOT / "hack" / "crd-schema-config.json"

# Only components that use ACM PolicyGenerator are scanned.
# telco-hub is excluded because it has no PolicyGenerator CR manifests.
SUBSCRIPTION_DIRS = {
    "ran": REPO_ROOT / "telco-ran" / "configuration" / "source-crs",
    "core": REPO_ROOT / "telco-core" / "configuration" / "reference-crs",
}


def detect_ocp_version():
    """Detect the target OCP version from the NROP Subscription channel."""
    nrop_sub = SUBSCRIPTION_DIRS["core"] / "required" / "scheduling" / "NROPSubscription.yaml"
    if not nrop_sub.exists():
        return None
    with open(nrop_sub) as f:
        doc = yaml.safe_load(f)
    channel = doc.get("spec", {}).get("channel", "")
    m = re.search(r"(\d+\.\d+)", str(channel))
    return m.group(1) if m else None


def scan_subscriptions():
    """Scan Subscription CRs. Returns {package_name: {channel, components}}."""
    results = {}
    for component, scan_dir in SUBSCRIPTION_DIRS.items():
        if not scan_dir.exists():
            continue
        for yaml_file in scan_dir.rglob("*Subscription*.yaml"):
            if "deprecated" in str(yaml_file):
                continue
            with open(yaml_file) as f:
                doc = yaml.safe_load(f)
            if not isinstance(doc, dict) or doc.get("kind") != "Subscription":
                continue

            spec = doc.get("spec", {})
            pkg_name = spec.get("name")
            channel = spec.get("channel")

            if pkg_name and channel:
                if pkg_name not in results:
                    results[pkg_name] = {"channel": channel, "components": set()}
                results[pkg_name]["components"].add(component)

    return results


def derive_ref(entry, channel, ocp_version):
    """Derive git ref from channel and ref_rule.

    ref_rule in the config controls how the ref is derived:
      - "release-ocp": use release-{OCP_VERSION}
      - "release-channel": use release-{version_from_channel}
      - absent/null: leave ref unchanged
    """
    ref_rule = entry.get("ref_rule")
    if not ref_rule:
        return entry["source"]["github"].get("ref")

    if ref_rule == "release-ocp" and ocp_version:
        return f"release-{ocp_version}"
    elif ref_rule == "release-channel" and channel:
        m = re.search(r"(\d+[\.\d]*)", channel)
        if m:
            return f"release-{m.group(1)}"

    return entry["source"]["github"].get("ref")


def main():
    parser = argparse.ArgumentParser(
        description="Update hack/crd-schema-config.json from Subscription CRs"
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Print updated config without writing")
    args = parser.parse_args()

    ocp_version = detect_ocp_version()
    if not ocp_version:
        print("ERROR: Could not detect OCP version", file=sys.stderr)
        sys.exit(1)
    print(f"Detected OCP version: {ocp_version}", file=sys.stderr)

    subscriptions = scan_subscriptions()

    with open(CONFIG_PATH) as f:
        config = json.load(f)

    for entry in config.get("crds", []):
        pkg = entry.get("package_name")
        sub = subscriptions.get(pkg) if pkg else None

        if sub:
            entry["subscription_channel"] = sub["channel"]
            entry["components"] = sorted(sub["components"])

        new_ref = derive_ref(entry, sub["channel"] if sub else None, ocp_version)
        if new_ref:
            entry["source"]["github"]["ref"] = new_ref

    output = json.dumps(config, indent=2) + "\n"

    if args.dry_run:
        print(output)
    else:
        with open(CONFIG_PATH, "w") as f:
            f.write(output)
        print(f"Updated {CONFIG_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
