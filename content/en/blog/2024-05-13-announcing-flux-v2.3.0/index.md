---
author: Stefan Prodan
date: 2024-05-13 15:00:00+00:00
title: Announcing Flux 2.3 GA
description: "We are thrilled to announce the release of Flux v2.3.0! Here you will find highlights of new features and improvements in this release."
url: /blog/2024/05/flux-v2.3.0/
tags: [announcement]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

We are thrilled to announce the release of [Flux v2.3.0](https://github.com/fluxcd/flux2/releases/tag/v2.3.0)!
In this post, we will highlight some of the new features and improvements included in this release.

## General availability of Flux Helm features and APIs

This release marks a significant milestone for the Flux project, after almost four years of development,
the helm-controller and the Helm related APIs have reached general availability.

The following Kubernetes CRDs have been promoted to GA:

- [HelmRelease](/flux/components/helm/helmreleases/) - `helm.toolkit.fluxcd.io/v2`
- [HelmChart](/flux/components/source/helmcharts/) - `source.toolkit.fluxcd.io/v1`
- [HelmRepository](/flux/components/source/helmrepositories/) - `source.toolkit.fluxcd.io/v1`

The Helm features and APIs have been battle-tested by the community in production and are now considered stable.
Future changes to the Helm APIs will be made in a backwards compatible manner,
and we will continue to support and maintain them for the foreseeable future.

### Enhanced Helm OCI support

The `HelmRelease` v2 API comes with a new field
[`.spec.chartRef`](/flux/components/helm/helmreleases/#chart-reference)
that adds support for referencing `OCIRepository` and `HelmChart` objects in a `HelmRelease`.
When using `.spec.chartRef` instead of `.spec.chart`, the controller allows the reuse
of a Helm chart version across multiple `HelmRelease` resources.

Starting with this version, the recommended way of referencing Helm charts stored
in container registries is through [OCIRepository](/flux/components/source/ocirepositories/).

Using `OCIRepository` objects instead of `HelmRepository`
improves the controller's performance and simplifies the debugging process.
The `OCIRepository` provides more flexibility in managing Helm charts,
as it allows targeting a Helm chart version by `tag`, `semver` or OCI `digest` pinning.
If a chart version gets overwritten in the container registry, the controller
will detect the change in the upstream OCI digest and reconcile the `HelmRelease`
resources accordingly.

Example of a `HelmRelease` referencing an `OCIRepository`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: metrics-server
spec:
  interval: 10m
  chartRef:
    kind: OCIRepository
    name: metrics-server
  driftDetection:
    mode: enabled
  values:
    apiService:
      create: true
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: metrics-server
spec:
  interval: 12h
  layerSelector:
    mediaType: "application/vnd.cncf.helm.chart.content.v1.tar+gzip"
    operation: copy
  url: oci://docker.io/bitnamicharts/metrics-server
  ref:
    semver: ">=7.0.0"
```

### Improved observability of Helm releases

By popular demand, the helm-controller now emits Kubernetes events annotated with the Helm chart `appVersion` 
in addition to the `version` info. When configuring [alerts](/flux/components/notification/alerts/) for Helm releases,
the `appVersion` is now available as a field in the alert metadata and is displayed in the notification messages.
The `appVersion` field is also included in the `HelmRelease` status, and in the `gotk_resource_info` Prometheus metrics.

When using an `OCIRepository` as the `HelmRelease` chart source, the controller will also include the OCI
digest of the Helm chart artifact in the Kubernetes events and the `HelmRelease` status.

### Benchmark results

To measure the real world impact of the helm-controller GA, we have set up benchmarks that measure
Mean Time To Production (MTTP). The MTTP benchmark measures the time it takes for Flux to deploy
application changes into production. Below are the results of the benchmark that ran on a GitHub
hosted runner (Ubuntu, 16 cores):

| Objects | Type          | Flux component       | Duration | Max Memory |
|---------|---------------|----------------------|----------|------------|
| 100     | OCIRepository | source-controller    | 25s      | 38Mi       |
| 100     | HelmRelease   | helm-controller      | 28s      | 190Mi      |
| 500     | OCIRepository | source-controller    | 45s      | 65Mi       |
| 500     | HelmRelease   | helm-controller      | 2m45s    | 250Mi      |
| 1000    | OCIRepository | source-controller    | 1m30s    | 67Mi       |
| 1000    | HelmRelease   | helm-controller      | 8m1s     | 490Mi      |

Compared to Flux v2.2, in this version the memory consumption of the helm-controller
has improved a lot, especially when the cluster has hundreds of CRDs registered.
In Flux v2.2, helm-controller on Kubernetes v1.28 is running out of memory
with 100 CRDs registered, while in Flux v2.3 on Kubernetes v1.29 it can handle
500+ CRDs without issues. Given these results, it is recommended
to upgrade the Kubernetes control plane to v1.29 and Flux to v2.3.

## Other notable changes

- The Flux `Kustomization` API gains two optional fields `.spec.namePrefix` and `.spec.nameSuffix`
  that can be used to specify a prefix and suffix to be added to the names of all managed resources.
- The kustomize-controller now supports the `--feature-gates=StrictPostBuildSubstitutions=true`
  flag, when enabled the post-build substitutions will fail if a variable without a default value is
  declared in files but is missing from the input vars.
- The notification-controller `Receiver` API has been extended to support
  [CDEvents](/flux/components/notification/receivers.md#cdevents).
- [Semver filtering](/flux/components/source/ocirepositories/#semverfilter-example) support has been added to the `OCIRepository` API.
- The Flux CLI boostrap capabilities have been extended to support [Oracle VBS](/flux/installation/bootstrap/oracle-vbs-git-repositories/) repositories.
- The Flux CLI gains a new command `flux envsubst` that can be used to replicate the behavior of the Flux `Kustomization` post-build substitutions.

## Breaking changes and deprecations

Deprecated fields have been removed from the `HelmRelease` v2 API:

- `.spec.chart.spec.valuesFile` replaced by `.spec.chart.spec.valuesFiles`
- `.spec.postRenderers.kustomize.patchesJson6902` replaced by `.spec.postRenderers.kustomize.patches`
- `.spec.postRenderers.kustomize.patchesStrategicMerge` replaced by `.spec.postRenderers.kustomize.patches`
- `.status.lastAppliedRevision` replaced by `.status.history.chartVersion`

The `HelmRelease` v2beta2 and v2beta1 APIs have been deprecated and will be removed in a future release.

The `HelmRepository` and `HelmChart` v1beta2 and v1beta1 APIs have been deprecated and will be removed in a future release.

## Installing or upgrading Flux

To install Flux, take a look at our [installation](https://fluxcd.io/flux/installation/) and [get started](https://fluxcd.io/flux/get-started/) guides.

To upgrade Flux from `v2.x` to `v2.3.0`, either [rerun `flux bootstrap`](https://fluxcd.io/flux/installation/#bootstrap-upgrade)
or use the [Flux GitHub Action](https://github.com/fluxcd/flux2/tree/main/action).

To upgrade the APIs in the manifests stored in Git:

1. Before upgrading, ensure that the `HelmRelease` v2beta2 YAML manifests
   are not using deprecated fields. Search for `valuesFile` and replace it with `valuesFiles`,
   replace `patchesJson6902` and `patchesStrategicMerge` with `patches`.
2. Commit and push the changes to the Git repository, then wait for Flux to reconcile the changes.
3. Upgrade the controllers and CRDs on the cluster using Flux v2.3 release.
4. Update the `apiVersion` field of the `HelmRelease` resources to `helm.toolkit.fluxcd.io/v2`.
5. Update the `apiVersion` field of the `HelmRepository` resources to `source.toolkit.fluxcd.io/v1`.
6. Update the `apiVersion` field of the `ImageUpdateAutomation` resources to `image.toolkit.fluxcd.io/v1beta2`.
7. Commit and push the changes to the Git repository.

Bumping the APIs version in manifests can be done gradually.
It is advised to not delay this procedure as the deprecated versions will be removed after 6 months.

## Over and out

If you have any questions, or simply just like what you read and want to get involved.
Here are a few good ways to reach us:

- Join our [upcoming dev meetings](https://fluxcd.io/community/#meetings).
- Join the [Flux mailing list](https://lists.cncf.io/g/cncf-flux-dev) and let us know what you need help with.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/).
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions).
- Follow [Flux on Twitter](https://twitter.com/fluxcd), or join the
  [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).
