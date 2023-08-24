---
title: "Flux events"
linkTitle: "Events"
description: "How to monitor the Flux events"
weight: 5
---

The Flux controllers emit [Kubernetes events][kubernetes-events] during the
reconciliation operation to provide information about the object being
reconciled. Unlike logs, events are always associated with an object, which is a
Flux resource in this case. Events are supplemental data that can be used along
with logs to provide a complete picture of controllers' operations. Some of
the events emitted by Flux controllers are also used to send notifications.
See the [Alerts docs](/flux/monitoring/alerts/) to learn more about the Flux
Alerts based on events from controllers. In the following sections, we will go
through the Flux events and how to interpret them.

## Kubernetes events

The Flux controller events about a resource contain the following fields:

- `type` can be `Normal` or `Warning`
- `firstTimestamp` timestamp in the ISO 8601 format
- `lastTimestamp` timestamp in the ISO 8601 format
- `message` info or warning description
- `reason` short machine understandable string
- `involvedObject` the API version, kind, name and namespace of the Flux object
- `metadata.annotations` the Flux specific metadata e.g. source revision
- `source.component` the Flux controller name where the event originated from.

### Examples

Example of a `Normal` event produced by kustomize-controller:

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

In the above example:
- The event is about a `Kustomization` named `flux-system` in the `flux-system`
  namespace, indicated by the `involvedObject` field.
- The event originates from `kustomize-controller`, indicated by the
  `source.component` field.
- The event is a `Normal` type event about a successful reconciliation,
  indicated by the `reason` and `message` fields.
- The `metadata.annotations` field `kustomize.toolkit.fluxcd.io/revision`
  contains information about the source revision that was successfully applied
  as a result of successful reconciliation of the Kustomization.

Example of a `Warning` event produced by source-controller:

```json
{
    "apiVersion": "v1",
    "count": 4,
    "eventTime": null,
    "firstTimestamp": "2023-08-22T20:24:06Z",
    "involvedObject": {
        "apiVersion": "source.toolkit.fluxcd.io/v1",
        "kind": "GitRepository",
        "name": "podinfo",
        "namespace": "default",
        "resourceVersion": "1284973",
        "uid": "2c2ed1da-556f-4793-863d-7d96e8bab3f5"
    },
    "kind": "Event",
    "lastTimestamp": "2023-08-22T20:24:18Z",
    "message": "failed to checkout and determine revision: unable to clone 'https://github.com/stefanprodan/podinfo': couldn't find remote ref \"refs/tags/v1.8.9\"",
    "metadata": {
        "creationTimestamp": "2023-08-22T20:24:06Z",
        "name": "podinfo.177dce48bc7db3a4",
        "namespace": "default",
        "resourceVersion": "1285016",
        "uid": "3c8f568a-c99b-4279-8093-6ef08fae325b"
    },
    "reason": "GitOperationFailed",
    "reportingComponent": "",
    "reportingInstance": "",
    "source": {
        "component": "source-controller"
    },
    "type": "Warning"
}
```

In the above example:
- The event is about a `GitRepository` named `podinfo` in the `default`
  namespace, indicated by the `involvedObject` field.
- The event originates from `source-controller`, indicated by the
  `source.component` field.
- The event is a `Warning` type event about a failed Git operation, indicated by
  the `reason` and `message` fields.

## Events inspection with kubectl

The events associated with a Flux resource can be queried using `kubectl events`
command:

```console
$ kubectl events -n flux-system --for kustomization/flux-system
LAST SEEN   TYPE     REASON                    OBJECT                      MESSAGE
58m         Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 448.00332ms, next run in 10m0s
48m         Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 486.826649ms, next run in 10m0s
38m         Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 502.282127ms, next run in 10m0s
28m         Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 543.745587ms, next run in 10m0s
18m         Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 465.177441ms, next run in 10m0s
8m27s       Normal   ReconciliationSucceeded   Kustomization/flux-system   Reconciliation finished in 494.543068ms, next run in 10m0s
```

This shows all the events associated with the queried resource in an hour.

## Events inspection with flux CLI

The events associated with a Flux resource can be queried using the `flux
events` CLI command:

```console
$ flux events --for Kustomization/flux-system
LAST SEEN       TYPE    REASON                  OBJECT                          MESSAGE
52m             Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 506.467ms, next run in 10m0s
42m             Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 531.072726ms, next run in 10m0
32m             Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 506.673992ms, next run in 10m0
22m             Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 512.255817ms, next run in 10m0
12m             Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 507.521248ms, next run in 10m0
2m31s           Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 448.00332ms, next run in 10m0s
```

This can also be used to watch all the events issues by the Flux controllers
across all the namespaces:

```console
$ flux events --all-namespaces --watch
NAMESPACE       LAST SEEN               TYPE    REASON                  OBJECT                          MESSAGE
flux-system     34m (x3 over 154m)      Normal  GitOperationSucceeded   GitRepository/flux-system       no changes since last reconcilation: observed revision 'main@sha1:4d768edba5d409feb60870dd3b0ac0d307299898'
flux-system     54m     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 486.814878ms, next run in 10m0s
flux-system     44m     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 486.203813ms, next run in 10m0s
flux-system     34m     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 512.160373ms, next run in 10m0s
flux-system     24m     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 543.806383ms, next run in 10m0s
flux-system     14m     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 524.293527ms, next run in 10m0s
flux-system     4m5s    Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 522.671955ms, next run in 10m0s
flux-system     47s     Normal  ReconciliationSucceeded Kustomization/flux-system       Reconciliation finished in 523.892245ms, next run in 10m0s
flux-system     34m     Normal  ReconciliationSucceeded Kustomization/monitoring-configs        Reconciliation finished in 104.609707ms, next run in 1h0m0s
flux-system     42s     Normal  ReconciliationSucceeded Kustomization/monitoring-configs        Reconciliation finished in 90.70521ms, next run in 1h0m0s
flux-system     34m     Normal  ReconciliationSucceeded Kustomization/monitoring-controllers    Reconciliation finished in 118.651968ms, next run in 1h0m0s
flux-system     39s     Normal  ReconciliationSucceeded Kustomization/monitoring-controllers    Reconciliation finished in 132.34839ms, next run in 1h0m0s
monitoring      34m (x3 over 154m)      Normal  ArtifactUpToDate        HelmChart/monitoring-kube-prometheus-stack      artifact up-to-date with remote revision: '48.3.3'
monitoring      34m (x3 over 154m)      Normal  ArtifactUpToDate        HelmChart/monitoring-loki-stack artifact up-to-date with remote revision: '2.9.11'
```

Refer to the [`flux events`](/flux/cmd/flux_events/) CLI docs to learn more
about it.


[kubernetes-events]: https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/
