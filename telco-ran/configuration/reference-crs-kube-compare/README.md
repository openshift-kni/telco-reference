# cluster-compare reference for telco-ran

This directory `reference-crs-kube-compare` contains all the references that can be
used to validate a DU profile cluster via the
[cluster-compare](https://github.com/openshift/kube-compare) plugin.

## Developer Notes

The reference must be kept in-sync with ../reference-crs

### CI Enforcement

The `make compare` target provided in this directory will compare the
reference, combining it with the examples in `default_value.yaml` and excluding
CRs listed in `compare_ignore`, and comparing the resulting reference-rendered
CRs with ../reference-crs

If this check fails, either the reference-crs or reference must be altered until
no differences are observed by running `make compare` locally.

### Update workflow

There is also a target `make sync` that will copy all reference-based CRs to
the ../reference-crs directory. Beware that any local edits to reference-crs will be
erased by this action, so this is intended for a workflow as follows:

- Edit the reference to reflect the intended behavior
- Update `default_value.yaml` to contain appropriate placeholder data
- Run `make sync` to update reference-crs to match the reference changes
