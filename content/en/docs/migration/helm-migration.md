---
title: "Migrate to the Helm Controller"
linkTitle: "Migrate from the Helm Operator"
description: "How to migrate from Helm Operator to Flux v2 and its Helm controller."
weight: 30
card:
  name: migration
  weight: 20
---

## Prerequisites

- Completed initial migration with the Flux migration guide

## Migration strategy

Due to the high number of changes to the API spec, there are no detailed instructions available to provide a simple migration path. But there is a [simple procedure to follow](#steps), which combined with the detailed list of [API spec changes](#api-spec-changes) should make the migration path relatively easy.

Here are some things to know:

- The Helm Controller will ignore the old custom resources (and the Helm Operator will ignore the new resources).
- Deleting a resource while the corresponding controller is running will result in the Helm release also being deleted.
- Deleting a `CustomResourceDefinition` will also delete all custom resources of that kind.
- If both the Helm Controller and Helm Operator are running, and both a new and old custom resources define a release, they will fight over the release.
- The Helm Controller will always perform an upgrade the first time it encounters a new `HelmRelease` for an existing release; this is [due to the changes to release mechanics and bookkeeping](#helm-storage-drift-detection-no-longer-relies-on-dry-runs).

The safest way to upgrade is to avoid deletions and fights by stopping the Helm Operator. Once the operator is not running, it is safe to deploy the Helm Controller (e.g., by following the [Get Started guide](../get-started/index.md), [utilizing `flux install`](../cmd/flux_install.md), or using the manifests from the [release page](https://github.com/fluxcd/helm-controller/releases)), and start replacing the old resources with new resources. You can keep the old resources around during this process, since the Helm Controller will ignore them.

## Steps

The recommended migration steps for a single `HelmRelease` are as follows:

1. Ensure the Helm Operator is not running, as otherwise the Helm Controller and Helm Operator will fight over the release.
1. Create a [`GitRepository` or `HelmRepository` resource for the `HelmRelease`](#defining-the-helm-chart), including any `Secret` that may be required to access the source. Note that it is possible for multiple `HelmRelease` resources to share a `GitRepository` or `HelmRepository` resource.
1. Create a new `HelmRelease` resource ([with the `helm.toolkit.fluxcd.io` group domain](#the-helmrelease-custom-resource-group-domain-changed)), define the `spec.releaseName` (plus the `spec.targetNamespace` and `spec.storageNamespace` if applicable) to match that of the existing release, and rewrite the configuration to adhere to the [API spec changes](#api-spec-changes).
1. Confirm the Helm Controller successfully upgrades the release.

### Example

As a full example, this is an old resource:

```yaml
---
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
spec:
  chart:
    repository: https://stefanprodan.github.io/podinfo
    name: podinfo
    version: 5.0.3
  values:
    replicaCount: 1
```

The custom resources for the Helm Controller would be:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 5m
  releaseName: default-podinfo
  chart:
    spec:
      chart: podinfo
      version: 5.0.3
      sourceRef:
        kind: HelmRepository
        name: podinfo
      interval: 10m
  values:
    replicaCount: 1
```

### Migrating gradually

Gradually migrating to the Helm Controller is possible by scaling down the Helm Operator while you move over resources, and scaling it up again once you have migrated some of the releases to the Helm Controller.

While doing this, make sure that once you scale up the Helm Operator again, there are no old and new `HelmRelease` resources pointing towards the same release, as they will fight over the release.

Alternatively, you can gradually migrate per namespace without ever needing to shut the Helm Operator down, enabling no continuous delivery interruption on most namespaces. To do so, you can customize the Helm Operator roles associated to its `ServiceAccount` to prevent it from interfering with the Helm Controller in namespaces you are migrating. First, create a new `ClusterRole` for the Helm Operator to operate in "read-only" mode cluster-wide:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: helm-operator-ro
rules:
  - apiGroups: ['*']
    resources: ['*']
    verbs:
      - get
      - watch
      - list
  - nonResourceURLs: ['*']
    verbs: ['*']
```

By default, [the `helm-operator` `ServiceAccount` is bound to a `ClusterRole` that allows it to create, patch and delete resources in all namespaces](https://github.com/fluxcd/helm-operator/blob/1baacd6dee865b57da80e0e767286ed68d578246/deploy/rbac.yaml#L9-L36). Bind the `ServiceAccount` to the new `helm-operator-ro` `ClusterRole`:

```diff
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
- name: helm-operator
+ name: helm-operator-ro
subjects:
  - kind: ServiceAccount
    name: helm-operator
    namespace: flux
```

Finally, create `RoleBindings` for each namespace, but the one you are currently migrating:

```yaml
# Create a `RoleBinding` for each namespace the Helm Operator is allowed to process `HelmReleases` in
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: helm-operator
  namespace: helm-operator-watched-namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: helm-operator
subjects:
  - name: helm-operator
    namespace: flux
    kind: ServiceAccount
# Do not create the following to prevent the Helm Operator from watching `HelmReleases` in `helm-controller-watched-namespace`
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: RoleBinding
# metadata:
#   name: helm-operator
#   namespace: helm-controller-watched-namespace
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: helm-operator
# subjects:
#   - name: helm-operator
#     namespace: flux
#     kind: ServiceAccount
```

If you are using [the Helm Operator chart](https://github.com/fluxcd/helm-operator/tree/master/chart/helm-operator), make sure to set `rbac.create` to `false` in order to take over `ClusterRoleBindings` and `RoleBindings` as you wish.

### Deleting old resources

Once you have migrated all your `HelmRelease` resources to the Helm Controller. You can remove all of the old resources by removing the old Custom Resource Definition.

```sh
kubectl delete crd helmreleases.helm.fluxcd.io
```
