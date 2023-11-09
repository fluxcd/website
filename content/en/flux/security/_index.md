---
title: "Security Documentation"
linkTitle: "Security"
description: "Flux Security documentation."
weight: 140
---

<!-- For doc writers: Step-by-step security instructions should live on the appropriate documentation pages.
To fulfil our promise to end users, we should briefly outline the context here,
and link to the more detailed instruction pages from each relevant part of this outline. -->

## Introduction

Flux has a multi-component design, and integrates with many other systems.

This document outlines an overview of security considerations for Flux components,
project processes, artifacts, as well as Flux configurable options and
what they enable for both Kubernetes cluster and external system security.

See our [security processes document](/security) for vulnerability reporting, handling,
and disclosure of information for the Flux project and community.

Please also have a look at [our security-related blog posts](/tags/security/).
We are writing there to inform you what we are doing to keep Flux and you safe!

## Signed container images

The Flux CLI and the controllers' images are signed using [Sigstore](https://www.sigstore.dev/) Cosign and GitHub OIDC.
The container images along with their signatures are published on GitHub Container Registry and Docker Hub.

To verify the authenticity of Flux's container images,
install [cosign](https://docs.sigstore.dev/cosign/installation/) v2 and run:

```console
$ cosign verify ghcr.io/fluxcd/source-controller:v1.0.0 \
  --certificate-identity-regexp=^https://github\\.com/fluxcd/.*$ \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com 

Verification for ghcr.io/fluxcd/source-controller:v1.0.0 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
```

We also wrote [a blog post](/blog/2022/02/security-image-provenance/) which discusses this in some more detail.

## Software Bill of Materials

For the Flux project we publish a Software Bill of Materials (SBOM) with each release.
The SBOM is generated with [Syft](https://github.com/anchore/syft) in the [SPDX](https://spdx.dev/) format.

The `spdx.json` file is available for download on the GitHub release page e.g.:

```shell
curl -sL https://github.com/fluxcd/flux2/releases/download/v2.0.0/flux_0.25.3_sbom.spdx.json | jq
```

The Flux controllers' images come with SBOMs for each CPU architecture,
you can extract the SPDX JSON using Docker's inspect command:

```shell
docker buildx imagetools inspect ghcr.io/fluxcd/source-controller:v1.0.0 \
    --format "{{ json (index .SBOM \"linux/amd64\").SPDX}}"
```

Or by using Docker's [sbom command](https://www.docker.com/blog/announcing-docker-sbom-a-step-towards-more-visibility-into-docker-images/):

```shell
docker sbom fluxcd/source-controller:v1.0.0
```

Please also refer to [this blog post](/blog/2022/02/security-the-value-of-sboms/)
which discusses the idea and value of SBOMs.

## SLSA Provenance 

Starting with Flux version 2.0.0, the build, release and provenance portions of the Flux
project supply chain provisionally meet [SLSA Build Level 3](https://slsa.dev/spec/v1.0/levels).

Please see the [SLSA Assessment](slsa-assessment.md) documentation for more details on how the
provenance is generated and how Flux complies with the SLSA requirements.

### Provenance verification

The provenance of the Flux release artifacts (binaries, container images, SBOMs, deploy manifests)
can be verified using the official SLSA verifier tool and Sigstore Cosign.
Please see the [SLSA provenance verification](slsa-assessment.md#provenance-verification) documentation
for more details on how to verify the provenance of Flux release artifacts.

### Buildkit attestations

The Flux controllers' images come with provenance attestations which follow
the [SLSA provenance schema version 0.2](https://slsa.dev/provenance/v0.2#schema).

The provenance attestations are generated at build time with
[Docker Buildkit](https://docs.docker.com/build/attestations/slsa-provenance/) and
include facts about the build process such as:

- Build timestamps
- Build parameters and environment
- Version control metadata
- Source code details
- Materials (files, scripts) consumed during the build

To extract the SLSA provenance JSON for a specific CPU architecture,
you can use Docker's inspect command:

```shell
docker buildx imagetools inspect ghcr.io/fluxcd/source-controller:v1.0.0 \
    --format "{{ json (index .Provenance \"linux/amd64\").SLSA}}"
```

Note that the `linux/amd64` can be replaced with another architecture variation of the image,
for example `linux/arm64` or `linux/arm/v7`.

## Scanning for CVEs

The Flux controllers' images are based on Alpine, they contain very few OS packages
and the controller's binary which is statically built using Go.

To properly scan Flux container images, the scanner must be able to detect the
Alpine apk packages and the Go modules included in the controller's Go binary.
The Go modules and apk packages are also available for inspection
in the attached [SBOM](#software-bill-of-materials).

The Flux team recommends users to scan the container images for CVEs using
[Trivy](https://github.com/aquasecurity/trivy),
which is an OSS scanner made by [Aqua Security](https://www.aquasec.com/).

To scan a controller image with Trivy:

```shell
trivy image ghcr.io/fluxcd/source-controller:v1.0.0
```

We ask users to keep Flux up-to-date on their clusters,
this is the only way to ensure a Flux deployment is free of CVEs.
New Flux versions are [published periodically](/flux/releases/#release-cadence),
and the container images are based on the latest Alpine and Go releases.
We offer a fully automated solution for keeping Flux up-to-date,
please see the Flux GitHub Actions
[documentation](/flux/flux-gh-action.md#automate-flux-updates)
for more details.

{{% alert color="warning" title="Reporting CVEs in Flux images" %}}
The Flux controllers are constantly being monitored for new CVEs, and the attack
surface for any vulnerability is assessed by maintainers. If a controller is considered
to be vulnerable, a new patch release will be issued immediately.

Given this, and while we do appreciate the effort, reporting CVEs found by a security
scanner through issues and/or the security mailing list is not necessary.
{{% /alert %}}

## Pod security standard

The controller deployments are configured in conformance with the
Kubernetes [restricted pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted):

- all Linux capabilities are dropped
- the root filesystem is set to read-only
- the seccomp profile is set to the runtime default
- run as non-root is enabled
- the filesystem group is set to 1337
- the user and group ID is set to 65534

## Controller permissions

While Flux integrates with other systems it is built on Kubernetes core controller-runtime
and properly adheres to Kubernetes security model including RBAC [^1].

Flux installs a set of [RBAC manifests](https://github.com/fluxcd/flux2/tree/main/manifests/rbac).
These include:

1. A `crd-controller` `ClusterRole`, which:
    - Has full access to all the Custom Resource Definitions defined by Flux controllers
    - Can get, list, and watch namespaces and secrets
    - Can get, list, watch, create, patch, and delete configmaps and their status
    - Can get, list, watch, create, patch, and delete coordination.k8s.io leases
2. A `crd-controller` `ClusterRoleBinding`:
    - References `crd-controller` `ClusterRole` above
    - Bound to a service accounts for every Flux controller
3. A `cluster-reconciler` `ClusterRoleBinding`:
    - References `cluster-admin` `ClusterRole`
    - Bound to service accounts for only `kustomize-controller` and `helm-controller`
4. A `flux-view` `ClusterRole`:
    - Grants the Kubernetes builtin `view` role read-only access to Flux Custom Resources
5. A `flux-edit` `ClusterRole`:
    - Grants the Kubernetes builtin `edit` and `admin` roles write access to Flux Custom Resources

Flux uses these two `ClusterRoleBinding` strategies in order to allow for clear access separation using tools
purpose-built for policy enforcement (OPA, Kyverno, admission controllers).

For example, the design allows all controllers to access Flux CRDs (binds to `crd-controller` `ClusterRole`),
but only binds the Flux reconciler controllers for Kustomize and Helm to `cluster-admin` `ClusterRole`,
as these are the only two controllers that manage resources in the cluster.

However in a [soft multi-tenancy setup](https://github.com/fluxcd/flux2-multi-tenancy),
Flux does not reconcile a tenant's repo under the `cluster-admin` role.
Instead, you specify a different service account in your manifest, and the Flux controllers will use
the Kubernetes Impersonation API under `cluster-admin` to impersonate that service account [^2].
In this way, policy restrictions for this service account are applied to the manifests being reconciled.
If the binding is not defined for the correct service account and namespace, it will fail.
The roles and permissions for this multi-tenancy approach
are described in detail here: <https://github.com/fluxcd/flux2-multi-tenancy>.

## Cross-Namespace reference policy

Flux's general premise is to follow Kubernetes best RBAC practices which forbid cross-namespace references to potential sensitive data, i.e. Secrets and ConfigMaps. For sources and events, Flux allows referencing resources from other Namespaces. In these cases, the policy is governed by each controller's `--no-cross-namespace-refs` flag. See the [Flux multi-tenancy configuration page](/flux/installation/configuration/multitenancy/) for further information on this flag.

## Further securing Flux Deployments

Beyond the baked-in security features of Flux, there are further best
practices that can be implemented to ensure your Flux deployment is as secure
as it can be. For more information, checkout the [Flux Security Best Practices](best-practices.md).

[^1]: However, by design cross-namespace references are an exception to RBAC.
Platform admins have the option to turn off cross-namespace references as described in the
[installation documentation](/flux/installation/configuration/multitenancy/).
[^2]: Platform admins have to option to enforce impersonation as described in the
[installation documentation](/flux/installation/configuration/multitenancy/).
