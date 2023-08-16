---
title: "Flux logs"
linkTitle: "Logs"
description: "How to monitor the Flux logs with Loki and Grafana"
weight: 3
---

The Flux controllers follow the Kubernetes structured logging conventions.

## Structured logging

The Flux controllers logs are written to `stderr` in JSON format, with the following common tags:

- `level` can be `debug`, `info` or `error`
- `ts` timestamp in the ISO 8601 format
- `msg` info or error description
- `error` error details (present when `level` is `error`)
- `controllerGroup` the Flux CR group
- `controllerKind` the Flux CR kind
- `name` The Flux CR name
- `namespace` The Flux CR namespace
- `reconcileID` the UID of the Flux reconcile operation

### Samples

Sample of a `info` log produced by kustomize-controller:

```json
{
  "level": "info",
  "ts": "2023-08-16T09:36:41.286Z",
  "controllerGroup": "kustomize.toolkit.fluxcd.io",
  "controllerKind": "Kustomization",
  "name": "redis",
  "namespace": "apps",
  "msg": "server-side apply completed",
  "revision": "main@sha1:30081ad7170fb8168536768fe399493dd43160d7",
  "output": {
    "ConfigMap/apps/redis": "created",
    "Deployment/apps/redis": "configured",
    "HorizontalPodAutoscaler/apps/redis": "deleted",
    "Service/apps/redis": "unchanged",
    "Secret/apps/redis": "skipped"
  }
}
```

Sample of an `error` log produced by kustomize-controller:

```json
{
  "level": "error",
  "ts": "2023-08-16T09:36:41.286Z",
  "controllerGroup": "kustomize.toolkit.fluxcd.io",
  "controllerKind": "Kustomization",
  "name": "redis",
  "namespace": "apps",
  "msg": "Reconciliation failed after 2s, next try in 5m0s",
  "revision": "main@sha1:f68c334e0f5fae791d1e47dbcabed256f4f89e68",
  "error": "Service/apps/redis dry-run failed, reason: Invalid, error: Service redis is invalid: spec.type: Unsupported value: Ingress"
}
```

## Log inspection with kubectl

```shell
kubectl -n flux-system logs deploy/kustomize-controller
```

## Log aggregation with Grafana Loki

To install Grafana Loki and Promtail in the `monitoring` namespace, apply the
[manifests/monitoring/loki-stack](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/loki-stack).

### Grafana dashboard

Control plane logs [http://localhost:3000/d/flux-logs](http://localhost:3000/d/flux-logs/flux-logs):

![Control plane logs dashboard](/img/logs-dashboard.png)
