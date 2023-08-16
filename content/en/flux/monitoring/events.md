---
title: "Flux events"
linkTitle: "Events"
description: "How to monitor the Flux events"
weight: 4
---

The Flux controllers emit Kubernetes events for every reconciliation operation.

## Kubernetes events

The Flux controllers events contain the following fields:

- `type` can be `Normal` or `Warning`
- `firstTimestamp` timestamp in the ISO 8601 format
- `lastTimestamp` timestamp in the ISO 8601 format
- `message` info or warning description
- `reason` short machine understandable string
- `involvedObject` the API version, kind, name and namespace of the Flux object
- `metadata.annotations` the Flux specific metadata e.g. source revision
- `source.component` the Flux controller name

### Samples

Sample of a `Normal` event produced by kustomize-controller:

```json
{
  "kind": "Event",
  "apiVersion": "v1",
  "metadata": {
    "name": "flux-system.177bd633e296a292",
    "namespace": "flux-system",
    "annotations": {
      "kustomize.toolkit.fluxcd.io/revision": "main@sha1:802723078affd3eb2a3898630261ab3ca5d6dd40"
    }
  },
  "involvedObject": {
    "kind": "Kustomization",
    "namespace": "flux-system",
    "name": "flux-system",
    "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
  },
  "reason": "ReconciliationSucceeded",
  "message": "Reconciliation finished in 436.493292ms, next run in 10m0s",
  "source": {
    "component": "kustomize-controller"
  },
  "firstTimestamp": "2023-08-16T10:26:43Z",
  "lastTimestamp": "2023-08-16T10:26:43Z",
  "type": "Normal",
}
```

## Events inspection with kubectl

```shell
kubectl events -n monitoring --for helmreleaase/kube-prom-stack
```
