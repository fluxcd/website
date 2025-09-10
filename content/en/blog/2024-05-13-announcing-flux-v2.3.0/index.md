---
author: Stefan Prodan
date: 2024-05-13 12:00:00+00:00
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

![](featured-image.png)

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
| 100     | HelmChart     | source-controller    | 25s      | 40Mi       |
| 100     | HelmRelease   | helm-controller      | 28s      | 190Mi      |
| 500     | HelmChart     | source-controller    | 45s      | 68Mi       |
| 500     | HelmRelease   | helm-controller      | 2m45s    | 250Mi      |
| 1000    | HelmChart     | source-controller    | 1m30s    | 110Mi      |
| 1000    | HelmRelease   | helm-controller      | 8m1s     | 490Mi      |

Compared to Flux v2.2, in this version the memory consumption of the helm-controller
has improved a lot, especially when the cluster has hundreds of CRDs registered.
In Flux v2.2, helm-controller on Kubernetes v1.28 runs out of memory
with only 100 CRDs registered. Whereas, in Flux v2.3 on Kubernetes v1.29, it can handle
500+ CRDs without issues. Given these results, it is recommended
to upgrade the Kubernetes control plane to v1.29 and Flux to v2.3.

## Image update automation improvements

The `ImageUpdateAutomation` API has been promoted to v1beta2 and
the image-automation-controller has been refactored to enhance the reconciliation process.

The v1beta2 API comes with a new 
[template model](/flux/components/image/imageupdateautomations/#message-template)
that can be used to customize the commit message when the controller updates the
image references in the Git repository. The commit template supports old and new values
for the changes made to the files containing the policy markers.
In addition, the commit message is included in the Kubernetes events emitted by the controller,
offering better visibility into the automation process.

The `ImageUpdateAutomation` API now supports selecting `ImagePolicies` using label selectors
in the new field [`.spec.policySelector`](/flux/components/image/imageupdateautomations/#policyselector).

### Migration to v1beta2 template model

To migrate to the v1beta2 API,
update the `apiVersion` field in the `ImageUpdateAutomation` resources to `image.toolkit.fluxcd.io/v1beta2`,
and modify the `messageTemplate` to use the `Changed` template data.

Example template:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: <automation-name>
spec:
  git:
    commit:
      messageTemplate: |-
        Automated image update
                
        Changes:
        {{ range .Changed.Changes -}}
        - {{ .OldValue }} -> {{ .NewValue }}
        {{ end -}}
        
        Files:
        {{ range $filename, $_ := .Changed.FileChanges -}}
        - {{ $filename }}
        {{ end -}}
```  

Example generated commit message:

```text
Automated image update

Changes:
- docker.io/nginx:1.25.4 -> docker.io/nginx:1.25.5
- docker.io/org/app:1.0.0 -> docker.io/org/app:1.0.1

Files:
- apps/my-app/deployment.yaml
```

For more examples and details,
see the [ImageUpdateAutomation documentation](/flux/components/image/imageupdateautomations/#message-template).

## Signatures verification with Notation

The Flux source-controller now supports verifying the authenticity of OCI artifacts signed with
[Notation](https://github.com/notaryproject/notation) (CNCF Notary project).

To enable Notation signature verification, please see the following documentation:

- [HelmChart verify](/flux/components/source/helmcharts/#notation)
- [OCIRepository verify](/flux/components/source/ocirepositories/#notation)

In addition, the Flux CLI now supports generating Kubernetes secrets with Notation trust policies,
using the `flux create secret notation` command.

Big thanks to Microsoft for contributing to the development of this feature!

## Terraform provider improvements

The [Flux Terraform provider](https://github.com/fluxcd/terraform-provider-flux) has undergone a major refactoring
and now supports air-gapped bootstrap, drift detection and correction for Flux components, and the ability to
upgrade and restore the Flux controllers in-cluster. Starting with this release, the provider is fully
compatible with OpenTofu.

The [provider documentation](https://github.com/fluxcd/terraform-provider-flux?tab=readme-ov-file#guides)
has been updated with examples and detailed usage instructions.

{{% alert color="info" title="New maintainer" %}}
We are very happy to announce that [Steven Wade](https://github.com/swade1987) has joined the Flux project
as a maintainer of the Terraform provider. Steven has been a long-time contributor to the Flux project
and we are excited to have him on board!
{{% /alert %}}

## Controllers improvements

- The Flux `Kustomization` API gains two optional fields `.spec.namePrefix` and `.spec.nameSuffix`
  that can be used to specify a prefix and suffix to be added to the names of all managed resources.
- The kustomize-controller now supports the `--feature-gates=StrictPostBuildSubstitutions=true`
  flag, when enabled the post-build substitutions will fail if a variable without a default value is
  declared in files but is missing from the input vars.
- The notification-controller `Receiver` API has been extended to support
  [CDEvents](/flux/components/notification/receivers.md#cdevents).
- The `OCIRepository` API has been extended with support for
  [semver filtering](/flux/components/source/ocirepositories/#semverfilter-example). 
- The `HelmChart` API v1 comes with a new optional field
  [`.spec.ignoreMissingValuesFiles`](/flux/components/source//helmcharts/#ignore-missing-values-files).

## CLI improvements

- The bootstrap capabilities have been extended to support [Oracle VBS](/flux/installation/bootstrap/oracle-vbs-git-repositories/) repositories.
- The bootstrap procedure for [Azure DevOps](/flux/installation/bootstrap/azure-devops/#bootstrap-using-ssh-keys) repositories has been update with support for SSH RSA SHA-2 keys.
- The `flux bootstrap` command gains a new flag `--ssh-hostkey-algos` that can be used to specify the host key algorithms to be used for SSH connections.
- The `flux bootstrap` and `flux install` commands now support the `--registry-creds` flag that can be used for generating an image pull secret for container images stored in private registries.
- A new command was added, `flux envsubst` that can be used to replicate the behavior of the Flux `Kustomization` post-build substitutions.
- The `flux create source oci` command now supports the `--verify-subject` and `--verify-issuer` for cosign keyless verification.
- New commands were added for managing HelmChart objects: `flux create|delete|export source chart`.

## Breaking changes and deprecations

Deprecated fields have been removed from the `HelmRelease` v2 API:

- `.spec.chart.spec.valuesFile` replaced by `.spec.chart.spec.valuesFiles`
- `.spec.postRenderers.kustomize.patchesJson6902` replaced by `.spec.postRenderers.kustomize.patches`
- `.spec.postRenderers.kustomize.patchesStrategicMerge` replaced by `.spec.postRenderers.kustomize.patches`
- `.status.lastAppliedRevision` replaced by `.status.history.chartVersion`

The following APIs have been deprecated and will be removed in a future release:

- `HelmRelease` v2beta2 and v2beta1
- `HelmChart` v1beta2 and v1beta1
- `HelmRepository` v1beta2 and v1beta1
- `ImageUpdateAutomation` v1beta1

## Supported versions

Flux v2.0 has reached end-of-life and is no longer supported.

Flux v2.3 supports the following Kubernetes versions:

| Distribution | Versions         |
|:-------------|:-----------------|
| Kubernetes   | 1.28, 1.29, 1.30 |
| OpenShift    | 4.15             |

Flux v2.3 is the first release end-to-end tested on OpenShift. Big thanks to
[Replicated](https://www.replicated.com/) for sponsoring the Flux project
with on-demand OpenShift clusters. For more information on how to bootstrap Flux on OpenShift,
see the [OpenShift installation guide](/flux/installation/configuration/openshift/).

{{% alert color="info" title="Enterprise support" %}}
Note that the CNCF Flux project offers support only for the latest
three minor versions of Kubernetes.

Backwards compatibility with older versions of Kubernetes and OpenShift is offered by vendors
such as [ControlPlane](https://control-plane.io/enterprise-for-flux-cd/) that provide
enterprise support for Flux.
{{% /alert %}}

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

## What's next for Flux?

The next milestone for the Flux project is v2.4, which is planned for Q3 2024
and will focus on the image automation APIs and S3-compatible storage APIs.
For more details on the upcoming features and improvements, see the [Flux project roadmap](/roadmap).

After the introduction of OCI Artifacts in 2022, we had a recurring ask from users about improving
the UX of running Flux fully decoupled from Git. In response, we made a proposal for a
`flux bootstrap oci` command and a new Terraform/OpenTofu provider that relies on
container registries as the unified data storage for the desired state of Kubernetes clusters.
The RFC can be found at [fluxcd/flux2#4749](https://github.com/fluxcd/flux2/pull/4749) and we 
welcome feedback from the community.

## Over and out

If you have any questions, or simply just like what you read and want to get involved,
here are a few good ways to reach us:

- Join our [upcoming dev meetings](https://fluxcd.io/community/#meetings).
- Join the [Flux mailing list](https://lists.cncf.io/g/cncf-flux-dev) and let us know what you need help with.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/).
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions).
- Follow [Flux on Twitter](https://twitter.com/fluxcd), or join the
  [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).
