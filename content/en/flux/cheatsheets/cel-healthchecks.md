---
title: "CEL cheatsheet"
linkTitle: "CEL Health Checks"
description: "Common Expression Language (CEL) expressions for checking the health of custom resources."
weight: 31
---

## About

The Kustomization API supports defining custom logic for performing health
checks on custom resources through the field
[`.spec.healthCheckExprs`](/flux/components/kustomize/kustomizations/#health-check-exprs).
This field accepts a set of Common Expression Language (CEL) expressions.

Here you can find a set of community-maintained CEL expressions for popular
custom resources.

## Contributing

For contributing to this library, open a pull request making changes to this file:

https://github.com/fluxcd/website/blob/main/content/en/flux/cheatsheets/cel-healthchecks.md

Please make sure to test your expressions and post evidence of their correctness
in the pull request, i.e. configure a Kustomization with the expressions, verify
that they work as expected and post logs or screenshots in the pull request.

The [CEL Playground](https://playcel.undistro.io/) is a useful resource for
testing your expressions. The input passed to each expression is the custom
resource object itself.

## FAQ

### CEL Macros

CEL provides various macros for use in computing health check expressions. They are documented in
the [CEL-spec language definition](https://github.com/google/cel-spec/blob/master/doc/langdef.md#macros).

### Using the `has(...)` CEL macro to handle missing fields

When working with custom resources that are progressing, it's common to reference fields that
do not yet exist in the custom resource. You can safe-guard your CEL expressions with the `has` macro,
by checking for property existence before accessing the property. For example, the following CEL
expression returns `false` if `status.attribute.ready` is not present on the resource.

```
has(status.attribute) && status.attribute.ready
```

However, it should be noted that `has` cannot check for the existence of top-level properties, such
as `status` or `data`.

## Library

The items in this library are sorted in alphabetical order.

### `CephCluster`

The `CephCluster` resource in this example is created by the `rook-ceph-cluster` Flux `HelmRelease`.

```yaml
healthChecks:
  - apiVersion: helm.toolkit.fluxcd.io/v2
    kind: HelmRelease
    name: rook-ceph-cluster
    namespace: rook-ceph
  - apiVersion: ceph.rook.io/v1
    kind: CephCluster
    name: rook-ceph
    namespace: rook-ceph
healthCheckExprs:
  - apiVersion: ceph.rook.io/v1
    kind: CephCluster
    failed: status.ceph.health == 'HEALTH_ERR'
    current: status.ceph.health == 'HEALTH_OK'
```

### `Cluster`

```yaml
healthCheckExprs:
  - apiVersion: cluster.x-k8s.io/v1beta1
    kind: Cluster
    failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `ClusterIssuer`

```yaml
healthCheckExprs:
  - apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `ClusterSecretStore`

```yaml
healthCheckExprs:
  - apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `Crossplane`

```yaml
healthCheckExprs:
  - apiVersion: pkg.crossplane.io/v1
    kind: Provider
    failed: status.conditions.filter(e, e.type == 'Healthy').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Healthy').all(e, e.status == 'True')
  - apiVersion: iam.aws.crossplane.io/v1beta1
    kind: Role
    failed: status.conditions.filter(e, e.type == 'Synced').all(e, e.status == 'False' && e.reason == 'ReconcileError')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `ScaledObject`

```yaml
healthCheckExprs:
  - apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `SealedSecret`

```yaml
healthCheckExprs:
  - apiVersion: bitnami.com/v1alpha1
    kind: SealedSecret
    failed: status.conditions.filter(e, e.type == 'Synced').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Synced').all(e, e.status == 'True')
```
