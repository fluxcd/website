---
title: "Flux Roadmap"
linkTitle: "Roadmap"
description: "Flux, Flagger and the GitOps Toolkit roadmap."
weight: 90
type: page
---

# Flux Project Roadmap

Here we are tracking the roadmaps of the Flux projects as a whole.

## Flux

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

### The road to Flux v2 GA

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
    - [ ] [Verify OCI artifacts with cosign](https://github.com/fluxcd/source-controller/issues/863)

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

### Security enhancements

Reach consensus on multi-tenancy enhancements and other security related proposals:

- [x] [RFC-0001](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization) Memorandum on the authorization model
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2092) Access control for cross-namespace source references
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2093) Flux Multi-Tenancy Security Profile
- [ ] [RFC](https://github.com/fluxcd/flux2/pull/2086) Define Flux tenancy models

### The road to Flux v1 feature parity

In our planning discussions we identified three areas of work:

- [x] Feature parity with Flux v1 in read-only mode
- [x] Feature parity with the image-update functionality in Flux v1
- [x] Feature parity with Helm Operator v1

#### Flux read-only feature parity

Flux v2 read-only is ready to try. See the [Getting
Started](/flux/get-started/) how-to, and the
[Migration
guide](/flux/migration/flux-v1-migration/).

This would be the first stepping stone: we want Flux v2 to be on-par with today's Flux in
[read-only mode](https://github.com/fluxcd/flux/blob/master/flux/faq.md#can-i-run-flux-with-readonly-git-access)
and [FluxCloud](https://github.com/justinbarrick/fluxcloud) notifications.

Goals

State | Item
----- | ----
:heavy_check_mark: | [Offer a migration guide for those that are using Flux in read-only mode to synchronize plain manifests](/flux/migration/flux-v1-migration/)
:heavy_check_mark: | [Offer a migration guide for those that are using Flux in read-only mode to synchronize Kustomize overlays](/flux/migration/flux-v1-migration/)
:heavy_check_mark: | [Offer a dedicated component for forwarding events to external messaging platforms](/flux/guides/notifications/)

Non-Goals

-  Migrate users that are using Flux to run custom scripts with `flux.yaml`
-  Automate the migration of `flux.yaml` kustomize users

Tasks

- [x]  <span style="color:grey">Design the events API</span>
- [x]  <span style="color:grey">Implement events in source and kustomize controllers</span>
- [x]  <span style="color:grey">Make the kustomize-controller apply/gc events on-par with Flux v1 apply events</span>
- [x]  <span style="color:grey">Design the notifications and events filtering API</span>
- [x]  <span style="color:grey">Implement a notification controller for Slack, MS Teams, Discord, Rocket</span>
- [x]  <span style="color:grey">Implement Prometheus metrics in source and kustomize controllers</span>
- [x]  <span style="color:grey">Review the git source and kustomize APIs</span>
- [x]  <span style="color:grey">Support [bash-style variable substitution](/flux/components/kustomize/kustomization/#variable-substitution) as an alternative to `flux.yaml` envsubst/sed usage</span>
- [x]  <span style="color:grey">Create a migration guide for `flux.yaml` kustomize users</span>
- [x]  <span style="color:grey">Include support for SOPS</span>

#### Flux image update feature parity

Image automation is available as a prerelease. See [this
guide](/flux/guides/image-update/) for how to
install and use it.

Goals

-  Offer components that can replace Flux v1 image update feature

Non-Goals

-  Maintain backwards compatibility with Flux v1 annotations
-  [Order by timestamps found inside image layers](https://github.com/fluxcd/flux2/discussions/802)

Tasks

- [x] <span style="color:grey">[Design the image scanning and automation API](https://github.com/fluxcd/flux2/discussions/107)</span>
- [x] <span style="color:grey">Implement an image scanning controller</span>
- [x] <span style="color:grey">Public image repo support</span>
- [x] <span style="color:grey">Credentials from Secret [fluxcd/image-reflector-controller#35](https://github.com/fluxcd/image-reflector-controller/pull/35)</span>
- [x] <span style="color:grey">Design the automation component</span>
- [x] <span style="color:grey">Implement the image scan/patch/push workflow</span>
- [x] <span style="color:grey">Integrate the new components in the Flux CLI [fluxcd/flux2#538](https://github.com/fluxcd/flux2/pull/538)</span>
- [x] <span style="color:grey">Write a guide for how to use image automation ([guide here](/flux/guides/image-update/))</span>
- [x] <span style="color:grey">ACR/ECR/GCR integration ([guide here](/flux/guides/image-update/#imagerepository-cloud-providers-authentication))</span>
- [x] <span style="color:grey">Write a migration guide from Flux v1 annotations ([guide here](/flux/migration/flux-v1-automation-migration/))</span>

#### Helm v3 feature parity

Helm support in Flux v2 is ready to try. See the [Helm controller
guide](/flux/guides/helmreleases/), and the [Helm
controller migration
guide](/flux/migration/helm-operator-migration/).

Goals

-  Offer a migration guide for those that are using Helm Operator with Helm v3 and charts from
   Helm and Git repositories

Non-Goals

-  Migrate users that are using Helm v2

Tasks

- [x]  <span style="color:grey">Implement a Helm controller for Helm v3 covering all the current release options</span>
- [x]  <span style="color:grey">Discuss and design Helm releases based on source API:</span>
    * [x]  <span style="color:grey">Providing values from sources</span>
    * [x]  <span style="color:grey">Conditional remediation on failed Helm actions</span>
    * [x]  <span style="color:grey">Support for Helm charts from Git</span>
- [x]  <span style="color:grey">Review the Helm release, chart and repository APIs</span>
- [x]  <span style="color:grey">Implement events in Helm controller</span>
- [x]  <span style="color:grey">Implement Prometheus metrics in Helm controller</span>
- [x]  <span style="color:grey">Implement support for values from `Secret` and `ConfigMap` resources</span>
- [x]  <span style="color:grey">Implement conditional remediation on (failed) Helm actions</span>
- [x]  <span style="color:grey">Implement support for Helm charts from Git</span>
- [x]  <span style="color:grey">Implement support for referring to an alternative chart values file</span>
- [x]  <span style="color:grey">Stabilize API</span>
- [x]  <span style="color:grey">[Create a migration guide for Helm Operator users](flux/migration/helm-operator-migration.md)</span>

## Flagger

### [GitOps Toolkit](https://github.com/fluxcd/flux2) compatibility

- [ ] Migrate Flagger to Kubernetes controller-runtime and [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
- [ ] Make the Canary status compatible with [kstatus](https://github.com/kubernetes-sigs/cli-utils)
- [ ] Make Flagger emit Kubernetes events compatible with Flux v2 notification API
- [ ] Integrate Flagger into Flux v2 as the progressive delivery component

### Integrations

- [ ] Add support for ingress controllers like HAProxy, ALB and Apache APISIX
