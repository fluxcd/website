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

The beta APIs will be replaced in time with stable versions. After an API reaches GA,
users have a six months window to upgrade the Flux CRDs and their Custom Resources
from beta to stable.
{{% /alert %}}

## Milestones

The GA roadmap has been split into separate milestones.
The Flux team's current focus is to finalise the tasks from the [Flux GitOps GA](#flux-gitops-ga-completed-in-july-2023) milestone.
We estimate that the Flux features part of this milestone will become generally available in the first quarter of 2023.

### Flux GitOps GA (Completed in July 2023)

The goal of this milestone is to make a generally available release for the Flux GitOps APIs,
and the Flux Git bootstrap & webhooks functionalities.

The completion of this milestone is marked by the [v2.0.0](https://github.com/fluxcd/flux2/releases/tag/v2.0.0) release of the Flux distribution and CLI. 

- [x] API promotions to GA
  - [x] [gitrepositories.source.toolkit.fluxcd.io/v1](https://github.com/fluxcd/source-controller/issues/947)
  - [x] [kustomizations.kustomize.toolkit.fluxcd.io/v1](https://github.com/fluxcd/kustomize-controller/issues/755)
  - [x] [receivers.notification.toolkit.fluxcd.io/v1](https://github.com/fluxcd/notification-controller/issues/436)

- [x] Git operations
  - [x] [Consolidate Git implementations](https://github.com/fluxcd/pkg/issues/245)
  - [x] [End-to-end testing for Git protocols](https://github.com/fluxcd/pkg/issues/334)
  - [x] [Bootstrap support for Git v2 proto (Azure DevOps and AWS CodeCommit)](https://github.com/fluxcd/flux2/issues/3273)
  - [x] [Git webhook receiver refactoring](https://github.com/fluxcd/notification-controller/pull/435)

- [x] Adopt Kubernetes server-side apply
  - [x] Rewrite the kustomize-controller reconciler using server-side apply
  - [x] Replace `kubectl` usage in Flux CLI with server-side apply (`fluxcd/pkg/ssa`)
  - [x] Preview local changes with server-side apply dry-run (`flux diff kustomization`)

- [x] Multi-tenancy lockdown
  - [x] [Allow setting a default service account for impersonation](https://github.com/fluxcd/flux2/issues/2340)
  - [x] [Allow disabling cross-namespace references](https://github.com/fluxcd/flux2/issues/2337)
  - [x] [Document multi-tenancy lockdown configuration](/flux/installation/configuration/multitenancy/)

- [x] Conformance testing
  - [x] End-to-end testing for bootstrap on AMD64 and ARM64 clusters
  - [x] End-to-end testing for Flux self-upgrade
  - [x] End-to-end testing for multi-tenancy lockdown

- [x] Terraform Provider
  - [x] [Implement `flux_bootstrap_git` resource](https://github.com/fluxcd/terraform-provider-flux/pull/332)
  - [x] [End-to-End testing with Kubernetes Kind](https://github.com/fluxcd/terraform-provider-flux/pull/411)
  - [x] [Migration guide to `flux_bootstrap_git`](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/guides/migrating-to-resource)
  - [x] [Bootstrap guide for GitHub](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/guides/bootstrap_github_ssh)
  - [x] [Bootstrap guide for GitLab](https://github.com/fluxcd/terraform-provider-flux/pull/438)
  
- [x] Documentation
  - [x] Install and bootstrap guides for Kubernetes (Generic Git, GitHub, GitLab, BitBucket)
  - [x] Install and bootstrap guides for managed Kubernetes (AWS, Azure, Google Cloud)
  - [x] `gitrepositories.source.toolkit.fluxcd.io` API specification
  - [x] `kustomizations.kustomize.toolkit.fluxcd.io` API specification

- [x] Kustomize v5 support
  - [x] [Update Flux controllers to Kustomize v5.0](https://github.com/fluxcd/flux2/issues/3564)
  - [x] [Update Kubernetes to 1.27.2](https://github.com/fluxcd/pkg/pull/534)

### Flux Helm GA (Q1 2024)

The goal of this milestone is to make a generally available release for the Flux Helm APIs
and the Flux Helm functionalities.

The completion of this milestone will be marked by the `v2.2.0` release of the Flux distribution and CLI.

- [ ] API promotions to GA
  - [ ] `helmrepositories.source.toolkit.fluxcd.io/v1`
  - [ ] `helmcharts.source.toolkit.fluxcd.io/v1`
  - [ ] `helmreleases.helm.toolkit.fluxcd.io/v2`

- [ ] Reconcilers
  - [x] [OCI support and Cosgin verification for HelmChart](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci#implementation-history)
  - [ ] [Atomic reconciliation of HelmReleases](https://github.com/fluxcd/helm-controller/pull/532)
  - [ ] [Standardize events and status conditions for HelmReleases](https://github.com/fluxcd/helm-controller/issues/487)

- [ ] CLI
  - [ ] [Cover more Helm release configuration options](https://github.com/fluxcd/flux2/issues/213)

- [ ] Documentation
  - [x] `helmrepositories.source.toolkit.fluxcd.io` API specification
  - [x] `helmcharts.source.toolkit.fluxcd.io` API specification
  - [ ] `helmreleases.helm.toolkit.fluxcd.io` API specification

### Flux Notifications GA (TBA)

- [ ] API promotions to GA
  - [ ] `alerts.notification.toolkit.fluxcd.io/v1`
  - [ ] `providers.notification.toolkit.fluxcd.io/v1`

This milestone's tasks haven't been determined yet.

### Flux Image Automation GA (TBA)

- [ ] API promotions to GA
  - [ ] `imagepolicies.image.toolkit.fluxcd.io/v1`
  - [ ] `imageupdateautomations.image.toolkit.fluxcd.io/v1`

This milestone's tasks haven't been determined yet.

### Flux S3-compatible APIs GA (TBA)

- [ ] API promotions to GA
  - [ ] `buckets.source.toolkit.fluxcd.io/v1`

This milestone's tasks haven't been determined yet.

### Flux OCI artifacts GA (TBA)

- [ ] API promotions to GA
  - [ ] `ocirepositories.source.toolkit.fluxcd.io/v1`

This milestone's tasks haven't been determined yet.

## Request for comments

The [RFC process](https://github.com/fluxcd/flux2/tree/main/rfcs)
provides a consistent and controlled path for substantial changes to enter Flux.

To keep track of the Flux project current direction and future plans, please see following RFCs:

- [x] [RFC-0001](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization) Memorandum on the authorization model
- [x] [RFC-0002](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci) Flux OCI support for Helm
- [x] [RFC-0003](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci) Flux OCI support for Kubernetes manifests
- [x] [RFC-0004](https://github.com/fluxcd/flux2/tree/main/rfcs/0004-insecure-http) Block insecure HTTP connections across Flux
- [x] [RFC-0005](https://github.com/fluxcd/flux2/pull/3233) Artifact `Revision` format and introduction of `Digest`
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2086) Define Flux tenancy models
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/4114) Passswordless authentication for Git repositories
