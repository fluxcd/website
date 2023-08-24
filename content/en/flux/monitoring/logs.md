---
title: "Flux logs"
linkTitle: "Logs"
description: "How to monitor the Flux logs with Loki and Grafana"
weight: 4
---

The Flux controllers follow the Kubernetes structured logging conventions. These
logs can be collected and analyzed to monitor the operations of the controllers.

The [fluxcd/flux2-monitoring-example][monitoring-example-repo] repository
provides a ready-made example setup to get started with monitoring Flux, which
includes [Loki-stack][loki-stack] to collect logs from all the Flux controllers
and explore them using Grafana. It is recommended to set up the monitoring
example before continuing with this document to follow along. Before getting
into Loki and Grafana setup, the following sections will describe the Flux logs
and how to interpret them.

## Controller logs

The default installation of Flux controllers write logs to `stderr` in JSON
format at the `info` log level. This can be configured using the
`--log-encoding` and `--log-level` flags in the controllers. Refer to the
[flux-system
kustomization](https://github.com/fluxcd/flux2-monitoring-example/blob/main/clusters/test/flux-system/kustomization.yaml)
for an example of how to patch the Flux controllers with flags. The following
example patch snippet can be appended to the existing set of patches to add a
log level flag and change the log level of the controller to `debug`.

```yaml
- op: add
  path: /spec/template/spec/containers/0/args/-
  value: --log-level="debug"
```

{{< note >}}
The patch configuration in the example only applies to a few targeted
controllers. Update the patch target to apply this to other controllers too.
{{< /note >}}

### Structured logging

The Flux controllers support structured logging with the following common
labels:

- `level` can be `debug`, `info` or `error`
- `ts` timestamp in the ISO 8601 format
- `msg` info or error description
- `error` error details (present when `level` is `error`)
- `controllerGroup` the Flux CR group
- `controllerKind` the Flux CR kind
- `name` The Flux CR name
- `namespace` The Flux CR namespace
- `reconcileID` the UID of the Flux reconcile operation

Sample of an `info` log produced by kustomize-controller:

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

The log labels shown above can be used to query for specific types of logs. For
example, error logs can be queried using the `error` label, the output of
successful reconciliation of Kustomization can be queried using the `output`
label, the logs about a specific controller can be queried using the
`controllerKind` label.

## Querying logs associated with resources

For querying logs associated with particular resources, the `flux logs` CLI
command can be used. It connects to the cluster, fetches the relevant Flux logs,
and filters them based on the query request. For example, to list the logs
associated with Kustomization `monitoring-configs`:

```console
$ flux logs --kind=Kustomization --name=monitoring-configs --namespace=flux-system --since=1m
...
2023-08-22T18:35:45.292Z info Kustomization/monitoring-configs.flux-system - All dependencies are ready, proceeding with reconciliation
2023-08-22T18:35:45.348Z info Kustomization/monitoring-configs.flux-system - server-side apply completed
2023-08-22T18:35:45.380Z info Kustomization/monitoring-configs.flux-system - Reconciliation finished in 88.208385ms, next run in 1h0m0s
```

Refer to the [`flux logs`](/flux/cmd/flux_logs/) CLI docs to learn more about
it.

## Log aggregation with Grafana Loki

In the [monitoring example repository][monitoring-example-repo], the monitoring
configurations can be found in the
[`monitoring/`](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring)
directory. `monitoring/controllers/` directory contains the configurations for
deploying kube-prometheus-stack and loki-stack. We'll discuss loki-stack below.
For Flux metrics collection using Prometheus, refer to the [Flux Prometheus
metrics](/flux/monitoring/metrics/) docs.

The configuration in the
[`monitoring/controllers/loki-stack`](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring/controllers/loki-stack)
directory creates a HelmRepository for the [Grafana
helm-charts](https://github.com/grafana/helm-charts) and a HelmRelease to
deploy the `loki-stack` chart in the `monitoring` namespace. Please see the
[values](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/loki-stack/release.yaml)
used for the chart and modify them accordingly.

Once deployed, [Loki][loki] and [Promtail][promtail] Pods get created, and Loki
is added as a data source in Grafana. Promtail aggregates the logs from all the
Pods in every node and sends them to Loki. Grafana can be used to query the logs
from Loki and analyze them. Refer to the [LogQL docs][logql] to see examples of
queries and learn more about querying logs.

### Grafana dashboard

The [example monitoring setup][monitoring-example-repo] provides a Grafana
dashboard in
[`monitoring/configs/dashboards/logs.json`](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring/configs/dashboards/logs.json)
that queries and shows logs from all the Flux controllers.

Control plane logs:

![Control plane logs dashboard](/img/grafana-logs-dashboard.png)

This can be used to browse logs from all the Flux controllers in a centralized
manner.


[monitoring-example-repo]: https://github.com/fluxcd/flux2-monitoring-example
[loki-stack]: https://github.com/grafana/helm-charts/tree/main/charts/loki-stack
[loki]: https://grafana.com/docs/loki/latest/
[promtail]: https://grafana.com/docs/loki/latest/clients/promtail/
[logql]: https://grafana.com/docs/loki/latest/logql/
