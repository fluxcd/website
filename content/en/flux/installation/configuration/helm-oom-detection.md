---
title: Flux near OOM detection for Helm
linkTitle: Helm OOM detection
description: "How to enable Helm near OOM detection"
weight: 21
---

When memory usage of the helm-controller exceeds the configured limit, the
controller will forcefully be killed by Kubernetes' OOM killer. This may result
in a Helm release being left in a `pending-*` state which causes the HelmRelease
to get stuck in an `another operation (install/upgrade/rollback) is in progress`
error loop.

To prevent this from happening, the controller offers an OOM watcher which can
be enabled with `--feature-gates=OOMWatch=true`. When enabled, the memory usage
of the controller will be monitored, and a graceful shutdown will be triggered
when it reaches a certain threshold (default 95% utilization).

When gracefully shutting down, running Helm actions may mark the release as
`failed`. Because of this, enabling this feature is best combined with
thoughtful [remediation strategies](/flux/components/helm/helmreleases/#configuring-failure-handling).

To enable near OOM detection [during bootstrap](boostrap-customization.md) add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Enable OOM watch feature
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=OOMWatch=true
      # Threshold at which to trigger a graceful shutdown (optional, default 95%)
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --oom-watch-memory-threshold=95
      # Interval at which to check memory usage (optional, default 500ms)
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --oom-watch-interval=500ms
    target:
      kind: Deployment
      name: helm-controller
```
