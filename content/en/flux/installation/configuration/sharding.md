---
title: "Flux sharding and horizontal scaling"
linkTitle: "Horizontal scaling"
description: "How to configure sharding for Flux controllers"
weight: 11
---

When Flux is managing tens of thousands of applications, it is advised to adopt
a sharding strategy to spread the load between multiple instances of Flux controllers.
To enable horizontal scaling, each controller can be deployed multiple times
with a unique label selector which is used as the sharding key.

What follows is a guide on how to bootstrap multiple controller instances and how to
shard the reconciliation of Flux resources using the `sharding.fluxcd.io/key` label.

## Bootstrap with sharding

At [bootstrap time](boostrap-customization.md), you can define the number of shards
and spin up a Flux controller instance for each shard.

First you'll need to create a Git repository and clone it locally, then
create the file structure required by bootstrap with:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

Then you'll create a dedicated directory inside `flux-system` for each shard:

```sh
mkdir -p clusters/my-cluster/flux-system/shard1
touch clusters/my-cluster/flux-system/shard1/kustomization.yaml
```

### Configure controller sharding

In the `shard1` directory generate a set of controller deployments that
will reconcile the Flux resources labels with `sharding.fluxcd.io/key: shard1`.

To spin up a dedicated source-controller, kustomize-controller and helm-controller instance,
use the following patches in `clusters/my-cluster/flux-system/shard1/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: flux-system
resources:
  - ../gotk-components.yaml
nameSuffix: "-shard1"
commonAnnotations:
  sharding.fluxcd.io/role: "shard"
patches:
  - target:
      kind: (Namespace|CustomResourceDefinition|ClusterRole|ClusterRoleBinding|ServiceAccount|NetworkPolicy)
      labelSelector: "app.kubernetes.io/part-of=flux"
    patch: |
      apiVersion: v1
      kind: all
      metadata:
          name: all
      $patch: delete
  - target:
      labelSelector: "app.kubernetes.io/component=notification-controller"
    patch: |
      apiVersion: v1
      kind: all
      metadata:
        name: all
      $patch: delete
  - target:
      kind: Deployment
      name: (image-reflector-controller|image-automation-controller)
    patch: |
      apiVersion: v1
      kind: Deployment
      metadata:
        name: all
      $patch: delete
  - target:
      kind: Service
      name: source-controller
    patch: |
      - op: replace
        path: /spec/selector/app
        value: source-controller-shard1
  - target:
      kind: Deployment
      name: source-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: source-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: source-controller-shard1
      - op: replace
        path: /spec/template/spec/containers/0/args/6
        value: --storage-adv-addr=source-controller-shard1.$(RUNTIME_NAMESPACE).svc.cluster.local.
  - target:
      kind: Deployment
      name: kustomize-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: kustomize-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: kustomize-controller-shard1
  - target:
      kind: Deployment
      name: helm-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: helm-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: helm-controller-shard1
  - target:
      kind: Deployment
      name: (source-controller|kustomize-controller|helm-controller)
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --watch-label-selector=sharding.fluxcd.io/key=shard1
```

The above configuration will generate three deployments `source-controller-shard1`,
`kustomize-controller-shard1` and `helm-controller-shard1` all configured 
with `--watch-label-selector=sharding.fluxcd.io/key=shard1`.

To enable these deployments at bootstrap, add the `shard1` directory to
the `clusters/my-cluster/flux-system/kustomization.yaml` resources:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
- shard1
patches:
  - target:
      kind: Deployment
      name: "(source-controller|kustomize-controller|helm-controller)"
      annotationSelector: "!sharding.fluxcd.io/role"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --watch-label-selector=!sharding.fluxcd.io/key
```

Note how this configuration excludes the sharding keys from the main controllers watch with
`--watch-label-selector=!sharding.fluxcd.io/key`. This ensures
that the main controllers will not reconcile any Flux resources labels with the sharding keys.

### Install and Upgrade shards

Push the changes to main branch:

```sh
git add -A && git commit -m "init flux" && git push
```

And run the bootstrap for `clusters/my-cluster`:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

Verify that the main controllers and the ones assigned to shard1 are running:

```console
$ kubectl -n flux-system get deployments 

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
helm-controller               1/1     1            1           1m
helm-controller-shard1        1/1     1            1           1m
kustomize-controller          1/1     1            1           1m
kustomize-controller-shard1   1/1     1            1           1m
notification-controller       1/1     1            1           1m
source-controller             1/1     1            1           1m
source-controller-shard1      1/1     1            1           1m
```

When upgrading Flux, either by rerunning bootstrap with a newer version or
by using the [Flux GitHub Actions](/flux/flux-gh-action.md#automate-flux-updates),
the sharded controllers will be automatically upgraded along with the main ones.

## Assign resources to shards

To assign a group of Flux resources to a particular shard, label
them with `sharding.fluxcd.io/key`.

For example, assuming you want to assign the reconciliation of an application
to the `shard1` controllers, label both the Flux source and its Kustomization
with `sharding.fluxcd.io/key: shard1`:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: podinfo
  namespace: default
  labels:
    sharding.fluxcd.io/key: shard1
spec:
  interval: 10m
  url: https://github.com/stefanprodan/podinfo
  ref:
    semver: 6.x
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: default
  labels:
    sharding.fluxcd.io/key: shard1
spec:
  interval: 10m
  targetNamespace: default
  sourceRef:
    kind: GitRepository
    name: podinfo
  path: ./kustomize
  prune: true
```

Note that Source object kinds which have a dependency on another kind
(i.e. `HelmChart` on a `HelmRepository`) need to have the same labels
applied to work as expected.

For example, assuming you want to assign the reconciliation of a Helm release
to the `shard1` controllers, label the HelmRelease, its chart and its repository
with `sharding.fluxcd.io/key: shard1`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
  labels:
    sharding.fluxcd.io/shard: shard1
spec:
  interval: 10m
  type: oci
  url: oci://ghcr.io/stefanprodan/charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
  labels:
    sharding.fluxcd.io/key: shard1
spec:
  interval: 10m
  chart:
    metadata:
      labels:
        sharding.fluxcd.io/key: shard1
    spec:
      chart: podinfo
      sourceRef:
        kind: HelmRepository
        name: podinfo
```

Note that with `.spec.chart.metadata.labels` we set the sharding key on the
generated Flux `HelmChart` object, so that both the Helm repository and charts
are managed by source-controller-shard1 instance.

### Bulk assign shards

Instead of manually labeling each Flux resource with a shard key, use a top-level
Flux Kustomization and automatically label all resources.

For example, assuming you want to assign a tenant to a particular shard, in the
root Flux Kustomization that reconcile the tenant's Flux sources, kustomizations and
Helm releases label these resources as follows:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenant1
  namespace: tenant1
spec:
  interval: 10m0s
  path: ./apps
  prune: true
  sourceRef:
    kind: GitRepository
    name: tenant1
  targetNamespace: tenant1
  commonMetadata:
    labels:
      sharding.fluxcd.io/key: shard1
  patches:
    - target:
        kind: HelmRelease
      patch: |
        apiVersion: helm.toolkit.fluxcd.io/v2beta2
        kind: HelmRelease
        metadata:
          name: all
        spec:
          chart:
            metadata:
              labels:
                sharding.fluxcd.io/key: shard1
```

With `.spec.commonMetadata.labels` we  set the shading key on all
the Flux resources and with the `.spec.patches` we set the same shading key
for all generated `HelmCharts`.
