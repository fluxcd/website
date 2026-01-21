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

### v2.8 (Q1 2026)

**Status**: In Progress

The primary goal of this milestone is to add support for Helm v4 to helm-controller,
and to reduce the mean time to recovery (MTTR) for app deployments.

- **OCI integrations**
  - [ ] [Add support for verification with cosign v3](https://github.com/fluxcd/source-controller/issues/1923)

- **Helm integrations**
  - [ ] [Add support for Helm v4 to helm-controller](https://github.com/fluxcd/helm-controller/issues/1300)
  - [x] [Add support for server-side apply](https://github.com/fluxcd/helm-controller/issues/1381)
  - [ ] [Keep track of managed objects in `.status.inventory`](https://github.com/fluxcd/helm-controller/issues/1352)
  - [ ] [Add support for custom health checks via CEL expressions](https://github.com/fluxcd/helm-controller/issues/1382)

- **Kustomize integrations**
  - [x] [Reduce the mean time to recovery (MTTR) in case of failed deployments](https://github.com/fluxcd/kustomize-controller/pull/1536)
  - [x] [Introduce custom SSA stage](https://github.com/fluxcd/kustomize-controller/pull/1571)

- **Git integrations**
  - [x] [Support looking up GitHub App installation ID from repository owner](https://github.com/fluxcd/pkg/issues/1065)

- **Alerting integrations**
  - [ ] [Support ArtifactGenerator notifications](https://github.com/fluxcd/source-watcher/issues/307)

- **Source extensions**
  - [x] [Allow ExternalArtifact as a source in ArtifactGenerator](https://github.com/fluxcd/source-watcher/issues/259)
  - [x] [Allow HelmChart as a source in ArtifactGenerator](https://github.com/fluxcd/source-watcher/issues/260)
  - [x] [Implement tarball extraction in ArtifactGenerator](https://github.com/fluxcd/source-watcher/issues/301)

- **Conformance testing**
  - [x] End-to-end testing for Kubernetes 1.35

- **EOL and Deprecations**
  - End support for Flux v2.5.x
  - End support for Kubernetes v1.32.x
  - Remove deprecated APIs in group `source.toolkit.fluxcd.io/v1beta2`
  - Remove deprecated APIs in group `kustomize.toolkit.fluxcd.io/v1beta2`
  - Remove deprecated APIs in group `helm.toolkit.fluxcd.io/v2beta2`

### v2.9 (Q2 2026)

**Status**: Provisional

The primary goal of this milestone is to add support for Helm [Chart API v3](https://helm.sh/de/community/hips/hip-0020),
and extend Flux server-side apply with field ignore rules.

- **Helm integrations**
  - [ ] Add support for Helm Chart API v3 to source-controller
  - [ ] Add support for Helm Chart API v3 to helm-controller

- **Kustomize integrations**
  - [ ] [Extend Server-Side Apply with field ignore rules](https://github.com/fluxcd/pkg/issues/696)

- **Alerting integrations**
  - [ ] [Add support for posting comments to GitHub/GitLab](https://github.com/fluxcd/notification-controller/issues/1073)

- **Source extensions**
  - [ ] [SDK for facilitating the development of 3rd party controllers based on the `ExternalArtifact` API](https://github.com/fluxcd/flux2/issues/5504)

- **Conformance testing**
  - [ ] End-to-end testing for Kubernetes 1.36

- **EOL and Deprecations**
  - End support for Flux v2.6.x
  - End support for Kubernetes v1.33.x
  - Remove deprecated APIs in group `image.toolkit.fluxcd.io/v1beta2`
  - Remove deprecated APIs in group `notification.toolkit.fluxcd.io/v1beta2`

### v2.10 (Q3 2026)

**Status**: Provisional

The primary goal of this milestone is to make a generally available release for the Flux Alerting APIs.

- **Alerting integrations**
  - [ ] Promote the `Event` API to `v1`
  - [ ] Promote the `Alert` API to `v1`
  - [ ] Promote the `Provider` API to `v1`

- **Source extensions**
  - [ ] Build external artifacts locally with `flux build artifact generator`

- **Conformance testing**
  - [ ] End-to-end testing for Kubernetes 1.37

- **EOL and Deprecations**
  - End support for Flux v2.7.x
  - End support for Kubernetes v1.34.x
  - Deprecate APIs in group `notification.toolkit.fluxcd.io/v1beta3`

## Request for comments

The [RFC process](https://github.com/fluxcd/flux2/tree/main/rfcs)
provides a consistent and controlled path for substantial changes to enter Flux.

To keep track of the Flux project's current direction and future plans, please see the following RFCs:

- [x] [RFC-0001](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization) Memorandum on the authorization model
- [x] [RFC-0002](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci) Flux OCI support for Helm
- [x] [RFC-0003](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci) Flux OCI support for Kubernetes manifests
- [x] [RFC-0004](https://github.com/fluxcd/flux2/tree/main/rfcs/0004-insecure-http) Block insecure HTTP connections across Flux
- [x] [RFC-0005](https://github.com/fluxcd/flux2/tree/main/rfcs/0005-artifact-revision-and-digest) Artifact `Revision` format and introduction of `Digest`
- [x] [RFC-0006](https://github.com/fluxcd/flux2/tree/main/rfcs/0006-cdevents) Flux CDEvents Receiver
- [x] [RFC-0007](https://github.com/fluxcd/flux2/tree/main/rfcs/0007-git-repo-passwordless-auth) Passwordless authentication for Git repositories
- [x] [RFC-0008](https://github.com/fluxcd/flux2/tree/main/rfcs/0008-custom-event-metadata-from-annotations) Custom Event Metadata from Annotations
- [x] [RFC-0009](https://github.com/fluxcd/flux2/tree/main/rfcs/0009-custom-health-checks) Custom Health Checks for Kustomization using Common Expression Language(CEL)
- [x] [RFC-0010](https://github.com/fluxcd/flux2/tree/main/rfcs/0010-multi-tenant-workload-identity) Multi-Tenant Workload Identity
- [x] [RFC-0011](https://github.com/fluxcd/flux2/tree/main/rfcs/0011-opentelemetry-tracing) OpenTelemetry Tracing
- [x] [RFC-0012](https://github.com/fluxcd/flux2/blob/main/rfcs/0012-external-artifact/) External Artifact API
