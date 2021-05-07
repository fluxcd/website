---
title: "Monitoring with Prometheus"
linkTitle: "Monitoring with Prometheus"
weight: 50
card:
  name: tasks
  weight: 40
---


This guide walks you through configuring monitoring for the Flux control plane.

Flux uses [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) to provide a monitoring stack:

The kube-promethus stack installs:
* **Prometheus** server - collects metrics from the toolkit controllers
* **Grafana** dashboards - displays the control plane resource usage and reconciliation stats
* **kube-state-metrics** -  generates metrics about the state of the objects from API server

## Install the kube-prometheus-stack

To install the monitoring stack with `flux`, first register the toolkit Git repository on your cluster:

```sh
flux create source git monitoring \
  --interval=30m \
  --url=https://github.com/fluxcd/flux2 \
  --branch=main
```

Then apply the [manifests/monitoring/kube-prometheus-stack](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/kube-prometheus-stack)
kustomization:

```sh
flux create kustomization monitoring \
  --interval=1h \
  --prune=true \
  --source=monitoring \
  --path="./manifests/monitoring/kube-prometheus-stack" \
  --health-check="Deployment/monitoring-kube-prometheus-operator.flux-system" \
  --health-check="Deployment/monitoring-grafana.flux-system"
```

## Create `PodMonitor` and configmap for Grafana dashboards

Note that the toolkit controllers expose the `/metrics` endpoint on port `8080`.
When using Prometheus Operator you need a `PodMonitor` object to configure scraping for the controllers.

Apply the [manifests/monitoring/monitoring-config](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/monitoring-config) kustomization:

```sh
flux create kustomization monitoring \
  --interval=1h \
  --prune=true \
  --source=monitoring \
  --path="./manifests/monitoring/monitoring-config" \
  --health-check="Deployment/monitoring-kube-prometheus-operator.flux-system" \
  --health-check="Deployment/monitoring-grafana.flux-system"
```

You can access Grafana using port forwarding:

```sh
kubectl -n flux-system port-forward svc/monitory-grafana 3000:80
```

## Grafana dashboards

Control plane dashboard [http://localhost:3000/d/gitops-toolkit-control-plane](http://localhost:3000/d/gitops-toolkit-control-plane/gitops-toolkit-control-plane):

![](/img/cp-dashboard-p1.png)

![](/img/cp-dashboard-p2.png)

Cluster reconciliation dashboard [http://localhost:3000/d/gitops-toolkit-cluster](http://localhost:3000/d/gitops-toolkit-cluster/gitops-toolkit-cluster-stats):

![](/img/cluster-dashboard.png)

If you wish to use your own Prometheus and Grafana instances, then you can import the dashboards from
[GitHub](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/grafana/dashboards).

## Metrics

For each `toolkit.fluxcd.io` kind,
the controllers expose a gauge metric to track the Ready condition status,
and a histogram with the reconciliation duration in seconds.

Ready status metrics:

```sh
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="True"}
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="False"}
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="Unknown"}
gotk_reconcile_condition{kind, name, namespace, type="Ready", status="Deleted"}
```

Time spent reconciling:

```
gotk_reconcile_duration_seconds_bucket{kind, name, namespace, le}
gotk_reconcile_duration_seconds_sum{kind, name, namespace}
gotk_reconcile_duration_seconds_count{kind, name, namespace}
```

Alert manager example:

```yaml
groups:
- name: GitOpsToolkit
  rules:
  - alert: ReconciliationFailure
    expr: max(gotk_reconcile_condition{status="False",type="Ready"}) by (namespace, name, kind) + on(namespace, name, kind) (max(gotk_reconcile_condition{status="Deleted"}) by (namespace, name, kind)) * 2 == 1
    for: 10m
    labels:
      severity: page
    annotations:
      summary: '{{ $labels.kind }} {{ $labels.namespace }}/{{ $labels.name }} reconciliation has been failing for more than ten minutes.'
```
