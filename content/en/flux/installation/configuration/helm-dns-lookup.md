---
title: Flux DNS lookups for Helm Releases
linkTitle: Helm DNS lookups
description: "How to allow Helm DNS lookups"
weight: 22
---
By default, the helm-controller will not perform DNS lookups when rendering Helm
templates in clusters because of potential [security
implications](https://github.com/helm/helm/security/advisories/GHSA-pwcw-6f5g-gxf8).

To enable DNS lookups [during bootstrap](boostrap-customization.md) add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Allow Helm DNS lookups
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=AllowDNSLookups=true
    target:
      kind: Deployment
      name: helm-controller
```
