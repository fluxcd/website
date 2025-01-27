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

## Library

The items in this library are sorted in alphabetical order.

### `Cluster`

```yaml
- apiVersion: cluster.x-k8s.io/v1beta1
  kind: Cluster
  failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
  current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `ClusterIssuer`

```yaml
- apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
  current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `ScaledObject`

```yaml
- apiVersion: keda.sh/v1alpha1
  kind: ScaledObject
  failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
  current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

### `SealedSecret`

```yaml
- apiVersion: bitnami.com/v1alpha1
  kind: SealedSecret
  failed: status.conditions.filter(e, e.type == 'Synced').all(e, e.status == 'False')
  current: status.conditions.filter(e, e.type == 'Synced').all(e, e.status == 'True')
```
