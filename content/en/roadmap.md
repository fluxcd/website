---
title: "Flux Roadmap"
linkTitle: "Roadmap"
description: "Flux and the GitOps Toolkit roadmap."
weight: 90
type: page
---

# Flux Roadmap

{{% alert color="info" title="Production readiness" %}}
The Flux latest [beta and stable APIs](/flux/components/)
(including their reconcilers) are well tested and safe to use in production environments.
The beta APIs will be replaced in time with stable versions.

To learn more about Flux supported versions and release cadence,
please see the [Flux release process](/flux/releases/).
{{% /alert %}}

## Milestones

The Flux project roadmap is divided into milestones representing minor releases,
each with a set of goals and tasks. The milestones marked as **provisional** are
subject to change based on the project's priorities and the community's feedback.

Please note that the Flux maintainers prioritize fixes to defects affecting GA APIs
and security issues over new features. Depending on the volume of incoming issues and
the complexity of the fixes, the roadmap may be adjusted and new features
may be postponed to the next milestone.

### v2.2 (Q4 2023)

**Status**: Completed (v2.2.0 [changelog](https://github.com/fluxcd/flux2/releases/tag/v2.2.0))

The primary goal of this milestone is to promote the `HelmRelease` beta API to `v2beta2` and to introduce
a new reconciliation model for Helm releases.

- **Helm integrations**
  - [x] [Promote `HelmRelease` API to v2beta2](https://v2-2.docs.fluxcd.io/flux/components/helm/helmreleases/)
  - [x] [Enhanced helm-controller reconciliation model](https://fluxcd.io/blog/2023/12/flux-v2.2.0/#enhanced-helmrelease-reconciliation-model)
  - [x] [Improved observability of Helm releases](https://fluxcd.io/blog/2023/12/flux-v2.2.0/#improved-observability-of-helm-releases)
  - [x] [Implement Helm Release drift detection and correction](https://fluxcd.io/blog/2023/12/flux-v2.2.0/#helm-release-drift-detection-and-correction)
  - [x] [Allow forcing and retrying Helm releases](https://fluxcd.io/blog/2023/12/flux-v2.2.0/#forcing-and-retrying-helm-releases)

- **OCI artifacts integrations**
  - [x] [Static Helm OCI repositories](https://v2-2.docs.fluxcd.io/flux/components/source/helmrepositories/#helm-oci-repository)
  - [x] [Cosign keyless verification for `HelmChart` artifacts](https://v2-2.docs.fluxcd.io/flux/components/source/helmcharts/#keyless-verification)
  - [x] [Cosign keyless verification for `OCIRepository` artifacts](https://v2-2.docs.fluxcd.io/flux/components/source/ocirepositories/#keyless-verification)
  - [x] [Allow connecting to insecure HelmRepositories](https://v2-2.docs.fluxcd.io/flux/components/source/helmrepositories/#insecure)
  - [x] [Allow connecting to insecure ImageRepositories](https://v2-2.docs.fluxcd.io/flux/components/image/imagerepositories/#insecure)

- **Git integrations**
  - [x] [Support for Gitea bootstrap](https://v2-2.docs.fluxcd.io/flux/installation/bootstrap/gitea/)
  - [x] [Support for BitBucket commit status updates](https://v2-2.docs.fluxcd.io/flux/components/notification/providers/#bitbucket-serverdata-center/)

- **Alerting integrations**
  - [x] [Promote the `Alert` API to `v1beta3`](https://v2-2.docs.fluxcd.io/flux/components/notification/alerts/)
  - [x] [Promote the `Provider` API to `v1beta3`](https://v2-2.docs.fluxcd.io/flux/components/notification/providers/)

- **Conformance testing**
  - [x] [Benchmark to measure the Mean Time To Production (MTTP)](https://github.com/fluxcd/flux-benchmark/)
  - [x] [End-to-end testing for Google Cloud integrations](https://github.com/fluxcd/flux2/tree/v2.2.0/tests/integration#gcp)
  - [x] [End-to-end testing for Kubernetes 1.29](https://github.com/fluxcd/flux2/pull/4484)

- **EOL and Deprecations**
  - End support for Kubernetes v1.25.x
  - Deprecate APIs in group `helm.toolkit.fluxcd.io/v2beta1`
  - Deprecate APIs in group `notification.toolkit.fluxcd.io/v2beta2`

### v2.3 (Q2 2024)

**Status**: In progress

The primary goal of this milestone is to make a generally available release for the Flux Helm APIs
and the Flux Helm functionalities.

- **Helm integrations**
  - [ ] Promote the `HelmRepository` API to `v1` GA
  - [ ] Promote the `HelmChart` API to `v1` GA
  - [ ] Promote the `HelmRelease` API to `v2` GA
  - [ ] Promote the Flux CLI Helm-related commands to GA
  - [ ] [Reuse charts between releases with OCIRepository](https://github.com/fluxcd/helm-controller/issues/789)
  - [ ] [Reuse existing HelmChart resource between releases](https://github.com/fluxcd/helm-controller/issues/204)

- **OCI artifacts integrations**
  - [x] [Notation verification for `HelmChart` artifacts](https://github.com/fluxcd/source-controller/pull/1075)
  - [x] [Notation verification for `OCIRepository` artifacts](https://github.com/fluxcd/source-controller/pull/1075)
  - [x] [Add `ref.semverFilter` to `OCIRepository` API](https://github.com/fluxcd/source-controller/issues/1391)

- **CDEvents integrations**
  - [x] [Extend the `Receiver` API with support for CDEvents](https://github.com/fluxcd/flux2/pull/4534)

- **Image automation**
  - [ ] Promote the `ImageUpdateAutomation` API to `v1beta2`
  - [ ] [Enhance image-automation-controller reconciliation model](https://github.com/fluxcd/image-automation-controller/issues/643)
  - [x] [Add support for selecting image policies with a label selector](https://github.com/fluxcd/image-automation-controller/pull/619)
  - [x] [Allow including the previous image tag in the commit message template](https://github.com/fluxcd/image-automation-controller/issues/437)

- **Conformance testing**
  - [ ] End-to-end testing for Kubernetes 1.30
  - [ ] [End-to-end testing for AWS integrations](https://github.com/fluxcd/flux2/issues/4619)
  - [ ] [End-to-end testing for OpenShift](https://github.com/fluxcd/flux2/issues/4625)

- **EOL and Deprecations**
  - End support for Flux v2.0.x
  - End support for Kubernetes v1.26.x
  - Deprecate APIs in group `helm.toolkit.fluxcd.io/v2beta2`
  - Deprecate APIs in group `image.toolkit.fluxcd.io/v1beta1`
  - Remove deprecated Terraform providers `flux_install` and `flux_sync`

### v2.4 (Q3 2024)

**Status**: Provisional

The primary goal of this milestone is to make a generally available release for the Flux image automation APIs
and S3-compatible storage APIs.

- **Image automation**
  - [ ] Promote the `ImageUpdateAutomation` API to `v1`
  - [ ] Promote the `ImageRepository` API to `v1`
  - [ ] Promote the `ImagePolicy` API to `v1`
  - [ ] [Add support for updating OCI digests](https://github.com/fluxcd/flux2/issues/4245)

- **S3-compatible storage integrations**
  - [ ] Promote the `Bucket` API to `v1`

- **OCI artifacts integrations**
  - [ ] [Cache registry credentials for cloud providers](https://github.com/fluxcd/pkg/issues/642)
  - [ ] [Enhance OCI Artifact support](https://github.com/fluxcd/source-controller/issues/1247)
  - [ ] [Add support for layer extraction from OCI artifacts with `ImageIndex`](https://github.com/fluxcd/source-controller/pull/1369)

- **Git integrations**
  - [ ] [Passwordless authentication for Git repositories](https://github.com/fluxcd/flux2/pull/4114)
  - [ ] Implement Workload Identity auth for Azure DevOps repositories
  - [ ] Implement GitHub App auth for GitHub repositories

- **Conformance testing**
  - [ ] End-to-end testing for Kubernetes 1.31

- **EOL and Deprecations**
  - End support for Flux v2.1.x
  - End support for Kubernetes v1.27.x
  - Remove deprecated APIs in group `kustomize.toolkit.fluxcd.io/v1beta1`
  - Remove deprecated APIs in group `source.toolkit.fluxcd.io/v1beta1`
  - Remove deprecated APIs in group `notification.toolkit.fluxcd.io/v1beta1`
  - Deprecate APIs in group `image.toolkit.fluxcd.io/v1beta2`

### v2.5 (TBD)

**Status**: Provisional

This milestone's tasks have not been determined yet.

- **Conformance testing**
  - [ ] End-to-end testing for Kubernetes 1.32

- **EOL and Deprecations**
  - End support for Flux v2.2.x
  - End support for Kubernetes v1.28.x
  - Remove deprecated APIs in group `helm.toolkit.fluxcd.io/v2beta1`
  - Remove deprecated APIs in group `image.toolkit.fluxcd.io/v1beta1`

## Request for comments

The [RFC process](https://github.com/fluxcd/flux2/tree/main/rfcs)
provides a consistent and controlled path for substantial changes to enter Flux.

To keep track of the Flux project current direction and future plans, please see following RFCs:

- [x] [RFC-0001](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization) Memorandum on the authorization model
- [x] [RFC-0002](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci) Flux OCI support for Helm
- [x] [RFC-0003](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci) Flux OCI support for Kubernetes manifests
- [x] [RFC-0004](https://github.com/fluxcd/flux2/tree/main/rfcs/0004-insecure-http) Block insecure HTTP connections across Flux
- [x] [RFC-0005](https://github.com/fluxcd/flux2/tree/main/rfcs/0005-artifact-revision-and-digest) Artifact `Revision` format and introduction of `Digest`
- [x] [RFC-0006](https://github.com/fluxcd/flux2/tree/main/rfcs/0006-cdevents) Flux CDEvents Receiver
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2086) Define Flux tenancy models
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/4114) Passswordless authentication for Git repositories
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/4528) Custom Health Checks for Kustomization using Common Expression Language(CEL)
