---
title: Enable Helm drift detection
linkTitle: Enable Helm drift detection
description: "How to enable Helm drift detection in Flux"
weight: 17
---

At present, Helm releases are not by default checked for drift compared to
cluster-state. To enable experimental drift detection, you must add the
`--feature-gates=DetectDrift=true` flag to the helm-controller Deployment.

Enabling it will cause the controller to check for drift on all Helm releases
using a dry-run Server Side Apply, triggering an upgrade if a change is detected.
For detailed information about this feature, [refer to the
documentation](/flux/components/helm/helmreleases/#drift-detection).

To enable drift detection [during bootstrap](_index.md) add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Enable drift detection feature
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=DetectDrift=true
      # Enable debug logging for diff output (optional)
      - op: replace
        path: /spec/template/spec/containers/0/args/2
        value: --log-level=debug
    target:
      kind: Deployment
      name: helm-controller
```
