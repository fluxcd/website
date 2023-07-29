---
title: Persistent storage for internal artifacts
linkTitle: Persistent storage for internal artifacts
description: "How to configure persistent storage for internal artifacts in Flux"
weight: 15
---

Flux maintains a local cache of artifacts acquired from external sources.
By default, the cache is stored in an `EmptyDir` volume, which means that after a restart,
Flux has to restore the local cache by fetching the content of all Git
repositories, Buckets, Helm charts and OCI artifacts. To avoid losing the cached artifacts,
you can configure source-controller with a persistent volume.

## Create a Kubernetes Persistent Volume Claim (PVC)

Create a Kubernetes PVC definition named `gotk-pvc.yaml` and place it in your `flux-system` directory:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gotk-pvc
  namespace: flux-system
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 2Gi
```

## Add the PVC to the source-controller

Add the PVC file to the `kustomization.yaml` resources and patch the source-controller volumes:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
  - gotk-pvc.yaml
patches:
  - patch: |
      - op: add
        path: '/spec/template/spec/volumes/-'
        value:
          name: persistent-data
          persistentVolumeClaim:
            claimName: gotk-pvc
      - op: replace
        path: '/spec/template/spec/containers/0/volumeMounts/0'
        value:
          name: persistent-data
          mountPath: /data
    target:
      kind: Deployment
      name: source-controller
```
