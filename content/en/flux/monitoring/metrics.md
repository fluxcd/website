---
title: "Flux Prometheus metrics"
linkTitle: "Metrics"
description: "How to monitor Flux with Prometheus Operator and Grafana"
weight: 1
---

## Reconcile metrics

Ready status metrics:

```sh
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="True"}
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="False"}
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="Unknown"}
```

Suspend status metrics:

```sh
gotk_suspend_status{kind, name, namespace}
```

Time spent reconciling:

```sh
gotk_reconcile_duration_seconds_bucket{kind, name, namespace, le}
gotk_reconcile_duration_seconds_sum{kind, name, namespace}
gotk_reconcile_duration_seconds_count{kind, name, namespace}
```

## Control plane metrics

Controller CPU and memory usage:

```sh
process_cpu_seconds_total{namespace, pod}
container_memory_working_set_bytes{namespace, pod}
```

Kubernetes API usage:

```shell
rest_client_requests_total{namespace, pod}
```

Controller runtime:

```shell
workqueue_longest_running_processor_seconds{name}
controller_runtime_reconcile_total{controller, result}
```

## Setup monitoring with kube-prom-stack

Flux uses [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
to provide a monitoring stack made out of:

* **Prometheus Operator** - manages Prometheus clusters atop Kubernetes
* **Prometheus** - collects metrics from the Flux controllers and Kubernetes API
* **Grafana** dashboards - displays the Flux control plane resource usage and reconciliation stats
* **kube-state-metrics** - generates metrics about the state of the Kubernetes objects

### Alert manager examples

## Flux Grafana dashboards

### Grafana annotations

