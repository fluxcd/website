---
title: "Flux Prometheus metrics"
linkTitle: "Metrics"
description: "How to monitor Flux with Prometheus Operator and Grafana"
weight: 2
---

{{% alert color="info" title="Metrics Deprecation" %}}
Some of the Flux controller metrics prior to v2.1.0 have been deprecated. Please
see the [Deprecated Resource Metrics](#warning-deprecated-resource-metrics)
section below to learn more about it.
{{< /alert >}}

Flux has native support for [Prometheus][prometheus] metrics to provide insights
into the state of the Flux components. These can be used to set up monitoring
for the Flux controllers. In addition, Flux Custom Resource metrics can also
be collected leveraging tools like [kube-state-metrics][kube-state-metrics].
This document provides information about Flux metrics that can be used to set up
monitoring, with some examples.

The [fluxcd/flux2-monitoring-example][monitoring-example-repo] repository
provides a ready-made example setup to get started with monitoring Flux. It is
recommended to set up the monitoring example before continuing with this
document to follow along. Before getting into the monitoring setup, the
following sections will describe the kinds of metrics that can be collected for
Flux.

## Controller metrics

The default installation of Flux controllers export Prometheus metrics at
port `8080` in the standard `/metrics` path. These metrics are about the inner
workings of the controllers.

Flux resource reconciliation duration metrics:

```
gotk_reconcile_duration_seconds_bucket{kind, name, namespace, le}
gotk_reconcile_duration_seconds_sum{kind, name, namespace}
gotk_reconcile_duration_seconds_count{kind, name, namespace}
```

Cache event metrics:

```
gotk_cache_events_total{event_type, name, namespace}
```

Controller CPU and memory usage:

```
process_cpu_seconds_total{namespace, pod}
container_memory_working_set_bytes{namespace, pod}
```

Kubernetes API usage:

```
rest_client_requests_total{namespace, pod}
```

Controller runtime:

```
workqueue_longest_running_processor_seconds{name}
controller_runtime_reconcile_total{controller, result}
```

In addition, many other Go runtime and [controller-runtime
metrics][controller-runtime-metrics] are also exported.

## Resource metrics

Metrics for the Flux custom resources can be used to monitor the deployment of
workloads. Since the use case for these metrics may vary depending on the
needs, it's hard to decide which fields of the resources would be useful to the
users. Hence, these metrics are not exported by the Flux controllers themselves
but can be collected and exported by using other tools that can read the custom
resource state from the kube-apiserver. One such tool is [kube-state-metrics
(KSM)][kube-state-metrics]. KSM is also deployed as part of
[kube-prometheus-stack][kube-prometheus-stack] and is used to export the metrics
of kubernetes core resources. It can be configured to also collect custom
resource metrics. The monitoring setup in
[flux2-monitoring-example][monitoring-example-repo] uses KSM to collect and 
export Flux custom resource metrics. 

In the [example monitoring setup][monitoring-example-repo], the metric
`gotk_resource_info` provides information about the current state of Flux
resources.

```
gotk_resource_info{customresource_group, customresource_kind, customresource_version, exported_namespace, name, ready, suspended, ...}
```

- `customresource_group` is the API group of the resource, for example
  `source.toolkit.fluxcd.io` for the Flux source API.
- `customresource_kind` is the kind of the resource, for example a
  `GitRepository` source.
- `customresource_version` is the API version of the resource, for example `v1`.
- `exported_namespace` is the namespace of the resource.
- `name` is the name of the resource.
- `ready` shows the readiness of the resource.
- `suspended` shows if the resource's reconciliation is suspended.

These are some of the common labels that are present in metrics for all the
kinds of resources. In addition, there are a few resource kind specific labels.
See the following table for a list of labels associated with specific resource
kind.

| Resource Kind         | Labels                                                                               |
| ---                   | ---                                                                                  |
| Kustomization         | `revision`, `source_name`                                                            |
| HelmRelease           | `revision`, `chart_name`, `chart_app_version`, `chart_source_name`, `chart_ref_name` |
| GitRepository         | `revision`, `url`                                                                    |
| Bucket                | `revision`, `endpoint`, `bucket_name`                                                |
| HelmRepository        | `revision`, `url`                                                                    |
| HelmChart             | `revision`, `chart_name`, `chart_version`                                            |
| OCIRepository         | `revision`, `url`                                                                    |
| Receiver              | `webhook_path`                                                                       |
| ImageRepository       | `image`                                                                              |
| ImagePolicy           | `source_name`                                                                        |
| ImageUpdateAutomation | `source_name`                                                                        |

{{< note >}}
The above metric may have extra labels after being collected in Prometheus. This
may be due to the default Prometheus scrape configuration used by
kube-prometheus-stack. Since they are about the kube-state-metrics service and
not about Flux itself, they can be ignored.
{{< /note >}}

`gotk_resource_info` is an example of a metric used to collect information about
the Flux resources. This metric can be customized to add more labels, or more
such metrics can also be created by changing the kube-state-metrics custom
resource state configuration. Please see [Flux custom Prometheus
metrics][custom-metrics] for details about them.

### :warning: Deprecated resource metrics

Prior to Flux v2.1.0, the individual Flux controllers used to export resource
metrics that they managed. They have been deprecated for custom metrics using
kube-state-metrics.

Users of the deprecated metrics `gotk_reconcile_condition` and
`gotk_suspend_status` can find the same information in the new
`gotk_resource_info` metric exported using kube-state-metrics. If needed, an
equivalent of `gotk_reconcile_condition` and `gotk_suspend_status` can be
created as a custom metric using the kube-state-metrics custom resource state
configuration. Please see [Flux custom Prometheus
metrics][custom-metrics] for details.

## Monitoring setup

In the [monitoring example repository][monitoring-example-repo], the monitoring configurations can be found in the
[`monitoring/`](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring)
directory. `monitoring/controllers/` directory contains the configurations for
deploying kube-prometheus-stack and loki-stack. We'll discuss
kube-prometheus-stack below. For Flux log collection using Loki, refer to the
[Flux logs](/flux/monitoring/logs/) docs.

The configuration in the `monitoring/controllers/kube-prometheus-stack/`
directory creates a HelmRepository of type OCI for the [prometheus-community
helm charts](https://github.com/prometheus-community/helm-charts) and a
HelmRelease to deploy the `kube-prometheus-stack` chart in the `monitoring`
namespace. This installs all the monitoring components in the `monitoring`
namespace. Please see the 
[values](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/kube-prometheus-stack/release.yaml)
used for the chart deployment and modify them accordingly.

The chart values used for configuring kube-state-metrics are in the file
[`kube-state-metrics-config.yaml`](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/kube-prometheus-stack/kube-state-metrics-config.yaml),
as seen in the
[kustomization.yaml](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/kube-prometheus-stack/kustomization.yaml),
which uses a kustomize ConfigMap generator to put the configurations in a
ConfigMap and use the chart values from the ConfigMap.
These values are merged with the inline chart values in the HelmRelease.
Kube-state-metrics values are in a separate file to make it easier to customize
the metrics it collects; refer to the [Flux custom Prometheus
metrics][custom-metrics] docs to see how they are used. Once
deployed with these values, the kube-state-metrics starts collecting and
exporting the Flux resource metrics.

To configure Prometheus to scrape Flux controller metrics, a
[PodMonitor](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/configs/podmonitor.yaml)
is used that selects all the Flux controller Pods and sets the metrics endpoint
to the `http-prom` port. Once created, the prometheus-operator will
automatically configure Prometheus to scrape the Flux controller metrics.

### Flux Grafana dashboards

The [example monitoring setup][monitoring-example-repo] provides two example
Grafana dashboards in
[`monitoring/configs/dashboards`](https://github.com/fluxcd/flux2-monitoring-example/tree/main/monitoring/configs/dashboards)
that use the Flux controller and resource metrics. The Flux Cluster Stats
dashboard shows the overall state of the Flux Sources and Cluster Reconcilers.
The Flux Control Plane dashboard shows the statistics of the various components
that constitute the Flux Control Plane and their operational metrics.

Control plane dashboard:

![Control Plane Dashboard - Part 1](/img/grafana-cp-dashboard-p1.png)

![Control Plane Dashboard - Part 2](/img/grafana-cp-dashboard-p2.png)

![Control Plane Dashboard - Part 3](/img/grafana-cp-dashboard-p3.png)

![Control Plane Dashboard - Part 4](/img/grafana-cp-dashboard-p4.png)

Cluster reconciliation dashboard:

![Cluster reconciliation dashboard - Part 1](/img/grafana-cluster-dashboard-p1.png)

![Cluster reconciliation dashboard - Part 2](/img/grafana-cluster-dashboard-p2.png)

More custom metrics can be created and used in the dashboards for monitoring
Flux.


[kube-state-metrics]: https://github.com/kubernetes/kube-state-metrics
[prometheus]: https://prometheus.io/
[monitoring-example-repo]: https://github.com/fluxcd/flux2-monitoring-example
[kube-prometheus-stack]: https://github.com/prometheus-operator/kube-prometheus
[controller-runtime-metrics]: https://book.kubebuilder.io/reference/metrics-reference
[custom-metrics]: /flux/monitoring/custom-metrics/
