---
title: Enable Helm repositories caching 
linkTitle: Enable Helm repositories caching
description: "How to enable Helm repositories caching in Flux"
weight: 16
---

The source-controller component in Flux fetches index files from remote Helm repositories to fetch information. 
For large repositories, this process can consume a significant amount of memory.

Helm repositories caching helps Flux's source-controller to store and reuse data from remote Helm repositories, 
reducing the need to repeatedly fetch data and conserving memory resources.

For large Helm repository index files, enable
caching to reduce the memory footprint of source-controller:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-max-size=10
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-ttl=60m
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-purge-interval=5m
    target:
      kind: Deployment
      name: source-controller
```

When `helm-cache-max-size` is reached, an error is logged and the index is instead
read from file. Cache hits are exposed via the `gotk_cache_events_total` Prometheus
metrics. Use this data to fine-tune the configuration flags.
