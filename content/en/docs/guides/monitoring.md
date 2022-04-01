---
title: "Monitoring with Prometheus"
linkTitle: "Monitoring with Prometheus"
description: "Monitoring Flux with Prometheus Operator and Grafana."
weight: 50
---

This guide walks you through configuring monitoring for the Flux control plane.

Flux uses [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
to provide a monitoring stack made out of:

* **Prometheus Operator** - manages Prometheus clusters atop Kubernetes
* **Prometheus** - collects metrics from the Flux controllers and Kubernetes API
* **Grafana** dashboards - displays the Flux control plane resource usage and reconciliation stats
* **kube-state-metrics** - generates metrics about the state of the Kubernetes objects

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
flux create kustomization monitoring-stack \
  --interval=1h \
  --prune=true \
  --source=monitoring \
  --path="./manifests/monitoring/kube-prometheus-stack" \
  --health-check="Deployment/kube-prometheus-stack-operator.monitoring" \
  --health-check="Deployment/kube-prometheus-stack-grafana.monitoring"
```

The above Kustomization will install the kube-prometheus-stack in the `monitoring` namespace.

{{% alert color="warning" title="Prometheus Configuration" %}}
Note that the above configuration is not suitable for production.
In order to configure long term storage for metrics
and highly availability for Prometheus consult the Helm
chart [documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).
{{% /alert %}}

## Install Flux Grafana dashboards

Note that the Flux controllers expose the `/metrics` endpoint on port `8080`.
When using Prometheus Operator you need a `PodMonitor` object to configure scraping for the controllers.

Apply the [manifests/monitoring/monitoring-config](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/monitoring-config)
containing the `PodMonitor` and the `ConfigMap` with Flux's Grafana dashboards:

```sh
flux create kustomization monitoring-config \
  --interval=1h \
  --prune=true \
  --source=monitoring \
  --path="./manifests/monitoring/monitoring-config"
```

You can access Grafana using port forwarding:

```sh
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

To log in to the Grafana dashboard, you can use the default credentials from the [kube-prometheus-stack chart](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml#L620):

```yaml
username: admin
password: prom-operator
```

## Flux dashboards

Control plane dashboard [http://localhost:3000/d/flux-control-plane](http://localhost:3000/d/flux-control-plane/flux-control-plane):

![Control Plane Dashboard - Part 1](/img/cp-dashboard-p1.png)

![Control Plane Dashboard - Part 2](/img/cp-dashboard-p2.png)

Cluster reconciliation dashboard [http://localhost:3000/d/flux-cluster](http://localhost:3000/d/flux-cluster/flux-cluster-stats):

![Cluster reconciliation dashboard](/img/cluster-dashboard.png)

If you wish to use your own Prometheus and Grafana instances, then you can import the dashboards from
[GitHub](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/grafana/dashboards).

## Annotations

![Annotations Dashboard](/img/grafana-annotation.png)

If you wish to overlap [flux notifications](/docs/components/notification/provider/#grafana) on dashboards you can do it by enabling the grafana annotations alert provider, the desired alerts and the annotation on the dashboard like shown below:

![Annotations configuration](/img/grafana-annotations-config.png)

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

Alert manager example:

```yaml
groups:
  - name: GitOpsToolkit
    rules:
      - alert: ReconciliationFailure
        expr: max(gotk_reconcile_condition{status="False",type="Ready"}) by (exported_namespace, name, kind) + on(exported_namespace, name, kind) (max(gotk_reconcile_condition{status="Deleted"}) by (exported_namespace, name, kind)) * 2 == 1
        for: 10m
        labels:
          severity: page
        annotations:
          summary: '{{ $labels.kind }} {{ $labels.exported_namespace }}/{{ $labels.name }} reconciliation has been failing for more than ten minutes.'
```
