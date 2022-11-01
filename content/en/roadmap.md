---
title: "Flux Roadmap"
linkTitle: "Roadmap"
description: "Flux and the GitOps Toolkit roadmap."
weight: 90
type: page
---

# Flux Roadmap

{{% alert color="info" title="Production readiness" %}}
The Flux custom resource definitions which are at `v1beta1`, `v1beta2` and `v2beta1`
and their controllers are considered stable and production ready.
Going forward, breaking changes to the beta CRDs will be accompanied by a conversion mechanism.
Please see the [Migration and Support Timetable](flux/migration/timetable.md) for our commitment to end users.
{{% /alert %}}

The following components are considered production ready:

- [source-controller](/flux/components/source)
- [kustomize-controller](/flux/components/kustomize)
- [notification-controller](/flux/components/notification)
- [helm-controller](/flux/components/helm)
- [image-reflector-controller](/flux/components/image)
- [image-automation-controller](/flux/components/image)

The following GitOps Toolkit APIs are considered production ready:

- `source.toolkit.fluxcd.io/v1beta2`
- `kustomize.toolkit.fluxcd.io/v1beta2`
- `notification.toolkit.fluxcd.io/v1beta1`
- `helm.toolkit.fluxcd.io/v2beta1`
- `image.toolkit.fluxcd.io/v1beta1`

## The road to Flux v2 GA

In our planning discussions we have identified these possible areas of work,
this list is subject to change while we gather feedback:

- **Stabilize the image automation APIs**
  - [x] Review the spec of `ImageRepository`, `ImagePolicy` and `ImageUpdateAutomation`
  - [x] Promote the image automation APIs to `v1beta1`

- **Conformance testing**
  - [x] End-to-end testing for Flux bootstrap on AMD64 and ARM64 clusters
  - [x] End-to-end testing for Flux image automation

- **Adopt Kubernetes server-side apply** ([fluxcd/flux2#1889](https://github.com/fluxcd/flux2/issues/1889))
  - [x] Replace `kubectl` usage in Flux CLI with server-side apply
  - [x] Rewrite the kustomize-controller reconciler using server-side apply

- **Multi-tenancy lockdown**
  - [x] [Allow setting a default service account for impersonation](https://github.com/fluxcd/flux2/issues/2340)
  - [x] [Allow disabling cross-namespace references](https://github.com/fluxcd/flux2/issues/2337)
  - [x] [Document multi-tenancy lockdown configuration](flux/installation.md#multi-tenancy-lockdown)

- **OCI Artifacts**
  - [x] [RFC-0002](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci) Flux OCI support for Helm
  - [x] [RFC-0003](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci) Flux OCI support for Kubernetes manifests
  - [x] [End-to-end testing for OIDC auth with AWS, Azure and Google Cloud container registries](hhttps://github.com/fluxcd/pkg/tree/main/oci/tests/integration)
  - [x] [Verify OCI artifacts with cosign](https://github.com/fluxcd/source-controller/issues/863)
  - [x] [Verify Helm charts with cosign](https://github.com/fluxcd/source-controller/issues/914)

- **API consolidation** ([fluxcd/flux2#1601](https://github.com/fluxcd/flux2/issues/1601))
  - [ ] Adopt Kubernetes [kstatus](https://github.com/kubernetes-sigs/cli-utils/tree/v0.25.0/pkg/kstatus#conditions) standard conditions
  - [ ] Standardize events and status conditions metadata
  - [ ] [Standardize the OpenAPI validation](https://github.com/fluxcd/flux2/issues/2993) for the `toolkit.fluxcd.io` CRDs

- **Git improvements** ([fluxcd/flux2#3039](https://github.com/fluxcd/flux2/issues/3039))
  - [ ] [Consolidate Git implementations](https://github.com/fluxcd/pkg/issues/245)
  - [ ] [End-to-end testing for Git protocols](https://github.com/fluxcd/pkg/issues/334)

- **Documentation improvements**
  - [x] Consolidate the docs under [fluxcd.io](https://fluxcd.io) website
  - [x] Gather feedback on the [migration guides](https://github.com/fluxcd/flux2/discussions/413) and address more use-cases
  - [x] Cloud specific guides (AWS, Azure, Google Cloud)
  - [x] Incident management and troubleshooting guides
    - [ ] [Developer guides](https://github.com/fluxcd/flux2/issues/1602#issuecomment-1131951114) for contributing to and extending Flux

## Security enhancements

Reach consensus on multi-tenancy enhancements and other security related proposals:

- [x] [RFC-0001](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization) Memorandum on the authorization model
- [x] [RFC-0004](https://github.com/fluxcd/flux2/tree/main/rfcs/0004-insecure-http) Block insecure HTTP connections across Flux
- [ ] [RFC-0005](https://github.com/fluxcd/flux2/pull/3233) Artifact `Revision` format and introduction of `Digest`
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2092) Access control for cross-namespace source references
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2093) Flux Multi-Tenancy Security Profile
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2086) Define Flux tenancy models
