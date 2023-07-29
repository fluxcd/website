---
title: Node affinity, tolerations and eviction
linkTitle: Node affinity, tolerations and eviction
description: "How to configure Node affinity, tolerations and eviction in Flux"
weight: 14
---

Flux controllers can be restricted to run specifically on certain nodes in the Kubernetes cluster. This enables better control over the placement of Flux controllers in the Kubernetes cluster and ensures they are deployed on dedicated nodes with the appropriate labels and taints.

Pin the Flux controllers to specific nodes with:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: role
                          operator: In
                          values:
                            - flux
            tolerations:
              - effect: NoSchedule
                key: role
                operator: Equal
                value: flux
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

The above configuration pins Flux to nodes tainted and labeled with:

```sh
kubectl taint nodes <my-node> role=flux:NoSchedule
kubectl label nodes <my-node> role=flux
```
