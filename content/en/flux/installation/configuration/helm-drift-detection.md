---
title: Flux drift detection for Helm Releases
linkTitle: Helm drift detection
description: "How to enable Helm drift detection in Flux"
weight: 20
---

At present, Helm releases are not by default checked for drift compared to
cluster-state. To enable experimental drift detection, you must add the
`--feature-gates=DetectDrift=true` flag to the helm-controller Deployment.

Enabling it will cause the controller to check for drift on all Helm releases
using a dry-run Server Side Apply, triggering an upgrade if a change is detected.
For detailed information about this feature, [refer to the
documentation](/flux/components/helm/helmreleases/#drift-detection).

To enable drift detection [during bootstrap](boostrap-customization.md) add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Enable drift detection and correction
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=DetectDrift=true,CorrectDrift=true
      # Enable debug logging for diff output (optional)
      - op: replace
        path: /spec/template/spec/containers/0/args/2
        value: --log-level=debug
    target:
      kind: Deployment
      name: helm-controller
```

{{% alert color="info" title="Disable drift correction" %}}
To help aid transition to this new feature, it is possible to enable drift detection without it correcting drift.
This can be done by setting the `CorrectDrift=false` feature flag in the above patch.
{{% /alert %}}
