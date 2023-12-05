---
title: "Flux custom Prometheus metrics"
linkTitle: "Custom metrics"
description: "How to extend the Flux Prometheus metrics with kube-state-metrics"
weight: 3
---

By default, the standard installation of Flux exports a specific set of metrics
about the controllers and their inner workings that may not serve the needs of
all the users. Some of these metrics are common across all the Flux controllers,
and some are very specific to a few controllers. It's not feasible to
add all the possible informational labels to these metrics, as that may increase
the cardinality of the metrics. Since these metrics are about the operations of
Flux, it may not be much of a benefit to add custom labels to these metrics,
as these are more useful for the people administering and maintaining Flux. Most
of the time, the users of Flux who interact with Flux through the Flux custom
resources want to know about the resources they work with. For example, the
state of GitRepositories and their branches or tag references. These metrics can
be scraped by using [kube-state-metrics (KSM)][kube-state-metrics], which is
part of the [kube-prometheus-stack][kube-prometheus-stack]. KSM can be
configured to add custom labels to the resource metrics, for example, some value
from the status of a resource or some arbitrary value like a team name, department name, etc.

## Set up kube-state-metrics

Kube-state-metrics can be installed along with the whole monitoring stack using
kube-prometheus-stack. The
[fluxcd/flux2-monitoring-example][monitoring-example-repo] repository contains
example configurations for deploying and configuring kube-prometheus-stack to
monitor Flux. These configurations will be discussed in detail in the following
sections to show how they can be customized.

The Kube-prometheus-stack Helm chart is used to install the monitoring stack.
The kube-state-metrics related configuration in the chart values exists in a
separate file called
[kube-state-metrics-config.yaml](https://github.com/fluxcd/flux2-monitoring-example/blob/main/monitoring/controllers/kube-prometheus-stack/kube-state-metrics-config.yaml).
It configures KSM to run in `custom-resource-state-only` mode. In this state,
KSM will not collect metrics for any of the Kubernetes core resources. The
`rbac` section provides KSM access to list and watch Flux custom resources. If
image-reflector-controller and image-automation-controllers are not used, the
API group (`image.toolkit.fluxcd.io`) and resources (`imagerepositories`,
`imagepolicies`, `imageupdateautomations`) can be removed. The
`customResourceState` section configures how the Flux metrics are composed.

Once deployed, KSM will start collecting the Flux resource metrics from the
kube-apiserver and exporting them as configured.

## Adding custom metrics

The example `customResourceState` values used in the above setup add a metric
called `gotk_resource_info` with labels `name`, `exported_namespace`,
`suspended`, `ready`, etc.

```yaml
- name: "resource_info"
  help: "The current state of a GitOps Toolkit resource."
  each:
    type: Info
    info:
    labelsFromPath:
      name: [metadata, name]
  labelsFromPath:
    exported_namespace: [metadata, namespace]
    suspended: [spec, suspend]
    ready: [status, conditions, "[type=Ready]", status]
    ...
```

This provides the current state of the Flux resources. It can be used to monitor
the readiness of Flux resources. This can be edited to add more labels; more
about that in the next section.

Similarly, more custom metrics can be added by appending them to the `metrics`
list. For example, to create a metric about the HelmRelease last applied
revision, append the HelmRelease resource metrics section:

```yaml
...
customResourceState:
  config:
    spec:
      resources:
        - groupVersionKind:
            group: helm.toolkit.fluxcd.io
            version: "v2beta2"
            kind: HelmRelease
          metricNamePrefix: gotk
          metrics:
            - name: "resource_info"
              help: "The current state of a GitOps Toolkit resource."
              each:
                type: Info
                info:
                  labelsFromPath:
                    name: [metadata, name]
              labelsFromPath:
                exported_namespace: [metadata, namespace]
                suspended: [spec, suspend]
                ready: [status, conditions, "[type=Ready]", status]
            - name: "helmrelease_version_info"
              help: "The version information of helm release resource."
              each:
                type: Info
                info:
                  labelsFromPath:
                    version: [status, lastAppliedRevision]
              labelsFromPath:
                name: [metadata, name]
                exported_namespace: [metadata, namespace]
                chartName: [spec, chart, spec, chart]
...
```

In the above, `gotk_resource_info` and `gotk_helmrelease_version_info` metrics
will be exported for HelmReleases.

```
# HELP gotk_resource_info The current state of a GitOps Toolkit resource.
# TYPE gotk_resource_info info
gotk_resource_info{customresource_group="helm.toolkit.fluxcd.io",customresource_kind="HelmRelease",customresource_version="v2beta2",exported_namespace="monitoring",name="kube-prometheus-stack",ready="True"} 1
gotk_resource_info{customresource_group="helm.toolkit.fluxcd.io",customresource_kind="HelmRelease",customresource_version="v2beta2",exported_namespace="monitoring",name="loki-stack",ready="True"} 1
# HELP gotk_helmrelease_version_info The version information of helm release resource.
# TYPE gotk_helmrelease_version_info info
gotk_helmrelease_version_info{chartName="kube-prometheus-stack",customresource_group="helm.toolkit.fluxcd.io",customresource_kind="HelmRelease",customresource_version="v2beta2",exported_namespace="monitoring",name="kube-prometheus-stack",version="48.3.1"} 1
gotk_helmrelease_version_info{chartName="loki-stack",customresource_group="helm.toolkit.fluxcd.io",customresource_kind="HelmRelease",customresource_version="v2beta2",exported_namespace="monitoring",name="loki-stack",version="2.9.11"} 1
```

## Adding custom metric labels

Custom labels can be added to metrics to create more meaningful monitoring
metrics. For example, a common `ownedBy` label across all the resources in a
cluster, `businessUnit` or `department` name from the labels of objects, etc.

For example, if the GitRepository objects are labelled with `department`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: foo
  namespace: bar
  labels:
    department: baz
spec:
  interval: 1h
  ref:
    branch: main
  url: https://github.com/fluxcd/flux2-monitoring-example
```

The KSM `customResourceState` value can be configured to extract the
department name, owned by team name and Git branch name, and include them as
labels in the `gotk_resource_info` metric of GitRepositories.

```yaml
...
customResourceState:
  config:
    spec:
      resources:
        - groupVersionKind:
            group: source.toolkit.fluxcd.io
            version: "v1"
            kind: GitRepository
          metricNamePrefix: gotk
          commonLabels:
            ownedBy: teamA
          labelsFromPath:
            department: [metadata, labels, department]
          metrics:
            - name: "resource_info"
              help: "The current state of a GitOps Toolkit resource."
              each:
                type: Info
                info:
                  labelsFromPath:
                    name: [metadata, name]
              labelsFromPath:
                exported_namespace: [metadata, namespace]
                suspended: [spec, suspend]
                ready: [status, conditions, "[type=Ready]", status]
                branch: [spec, ref, branch]
...
```

The above configuration will result in the following metric

```
gotk_resource_info{branch="main",customresource_group="source.toolkit.fluxcd.io",customresource_kind="GitRepository",customresource_version="v1",department="baz",exported_namespace="bar",name="foo",ownedBy="teamA",ready="True"} 1
```

It contains the `ownedBy="teamA"`, `department="baz"` and `branch="main"`
labels. Similarly, more custom labels can be added depending on the need.

Refer to the [kube-state-metrics custom-resource state configuration
docs][ksm-customresourcestate-metrics] to learn more about customizing the
metrics.


[kube-state-metrics]: https://github.com/kubernetes/kube-state-metrics
[monitoring-example-repo]: https://github.com/fluxcd/flux2-monitoring-example
[kube-prometheus-stack]: https://github.com/prometheus-operator/kube-prometheus
[ksm-customresourcestate-metrics]: https://github.com/kubernetes/kube-state-metrics/blob/main/docs/customresourcestate-metrics.md
