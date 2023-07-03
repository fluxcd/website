---
title: "SLSA Assessment"
linkTitle: "SLSA Assessment"
description: "Flux assessment of SLSA Level 3 requirements."
weight: 140
---

## Introduction

Supply Chain Levels for Software Artifacts, or SLSA (pronounced "salsa"),
is a security framework which aims to prevent tampering and secure artifacts in a project.
SLSA is designed to support automation that tracks code handling from source to binary
protecting against tampering regardless of the complexity of the software supply chain.

Starting with Flux version 2.0.0, the build, release and provenance portions of the Flux
project supply chain provisionally meet [SLSA Build Level 3](https://slsa.dev/spec/v1.0/levels).

## SLSA Requirements and Flux Compliance State

What follows is an assessment made by members of the Flux core maintainers team
on how Flux v2.0 complies with the Build Level 3 requirements as specified by
[SLSA v1.0](https://slsa.dev/spec/v1.0/levels).

### Producer Requirements

| Requirement                          | Required at SLSA L3 | Met by Flux |
|--------------------------------------|---------------------|-------------|
| Choose an appropriate build platform | Yes                 | Yes         |
| Follow a consistent build process    | Yes                 | Yes         |
| Distribute provenance                | Yes                 | Yes         |

#### Choose an appropriate build platform

> The producer MUST choose a builder capable of producing Build Level 3 provenance.

- The Flux project uses Git for source code management and the Flux project's repositories are hosted on GitHub under
  the FluxCD organization.
- All the Flux maintainers are required to have two-factor authentication enabled and to sign-off all their
  contributions.
- The Flux project uses GitHub Actions and GitHub Runners for building all its release artifacts.
- The build and release process runs in isolation on an ephemeral environment provided by GitHub-hosted runners.

#### Follow a consistent build process

> The producer MUST build their artifact in a consistent manner such that verifiers can form expectations about the
> build process.

- The build and release process is defined in code (GitHub Workflows and Makefiles) and is kept under version control.
- The GitHub Workflows make use of GitHub Actions pinned to their Git commit SHA and are kept up-to-date using GitHub
  Dependabot.
- All changes to build and release process are done via Pull Requests that must be approved by at least one Flux
  maintainer.
- The release process can only be kicked off by a Flux maintainer by pushing a Git tag in the semver format.

#### Distribute provenance

> The producer MUST distribute provenance to artifact consumers.

- The Flux project uses the
  official [SLSA GitHub Generator project](https://github.com/slsa-framework/slsa-github-generator) for provenance
  generation and distribution.
- The provenance for the release artifacts published to GitHub releases (binaries, SBOMs, deploy manifests, source code)
  is generated using the `generator_generic_slsa3` GitHub Workflow provided by
  the [SLSA GitHub Generator project](https://github.com/slsa-framework/slsa-github-generator).
- The provenance for the release artifacts published to GitHub Container Registry and to DockerHub (Flux controllers
  multi-arch container images) is generated using the `generator_container_slsa3` GitHub Workflow provided by
  the [SLSA GitHub Generator project](https://github.com/slsa-framework/slsa-github-generator).

### Build Platform Requirements

#### Provenance generation

| Requirement               | Required at SLSA L3 | Met by Flux |
|---------------------------|---------------------|-------------|
| Provenance Exists         | Yes                 | Yes         |
| Provenance is Authentic   | Yes                 | Yes         |
| Provenance is Unforgeable | Yes                 | Yes         |

> The build process MUST generate provenance that unambiguously identifies the output package by cryptographic digest
> and describes how that package was produced.

- The Flux project release workflows make use of the
  official [SLSA GitHub Generator project](https://github.com/slsa-framework/slsa-github-generator) for provenance
  generation.
- The provenance file stores the SHA-256 hashes of the release artifacts (binaries, SBOMs, deploy manifests, source
  code).
- The provenance identifies the Flux container images using their digest in SHA-256 format.

> Consumers MUST be able to validate the authenticity of the provenance attestation in order to ensure integrity and
> define trust.

- The provenance is signed by Sigstore Cosign using the GitHub OIDC identity and the public key to verify the provenance
  is stored in the public [Rekor transparency log](https://docs.sigstore.dev/rekor/overview/).
- The release process and the provenance generation are run in isolation on an ephemeral environment provided by
  GitHub-hosted runners.
- The provenance of the Flux release artifacts (binaries, container images, SBOMs, deploy manifests) can be verified
  using the official [SLSA verifier tool](https://github.com/slsa-framework/slsa-verifier).

> Provenance MUST be strongly resistant to forgery by tenants.

- The provenance generation workflows run on ephemeral and isolated virtual machines which are fully managed by GitHub.
- The provenance signing secrets are ephemeral and are generated through
  Sigstore's [keyless signing](https://github.com/sigstore/cosign/blob/main/KEYLESS.md) procedure.
- The [SLSA GitHub generator](https://github.com/slsa-framework/slsa-github-generator) runs on separate virtual machines
  than the build and release process, so that the Flux build scripts don't have access to the signing secrets.

#### Isolation strength

| Requirement | Required at SLSA L3 | Met by Flux |
|-------------|---------------------|-------------|
| Hosted      | Yes                 | Yes         |
| Isolated    | Yes                 | Yes         |

> All build steps ran using a hosted build platform on shared or dedicated infrastructure.

- The release process and the provenance generation are run in isolation on an ephemeral environment provided by
  GitHub-hosted runners.
- The provenance generation is decoupled from the build process,
  the [SLSA GitHub generator](https://github.com/slsa-framework/slsa-github-generator) runs on separate virtual machines
  fully managed by GitHub.

> The build platform ensured that the build steps ran in an isolated environment, free of unintended external influence.

- The release process can only be kicked off by a Flux maintainer by pushing a Git tag in the semver format.
- The release process runs on ephemeral and isolated virtual machines which are fully managed by GitHub.
- The release process can't access the provenance signing key, because the provenance generator runs in isolation on
  separate GitHub-hosted runners.

## Provenance verification

The provenance of the Flux release artifacts (binaries, container images, SBOMs, deploy manifests)
can be verified using the official [SLSA verifier tool](https://github.com/slsa-framework/slsa-verifier).

### Container images

The provenance of the Flux multi-arch container images hosted on GitHub Container Registry
and DockerHub can be verified using the official [SLSA verifier tool](https://github.com/slsa-framework/slsa-verifier)
and [Sigstore Cosign](https://github.com/sigstore/cosign).

What follows is the list of Flux components along with their minimum required version for provenance verification.

| Git Repository                                                                       | Images                                                                                        | Min version | Provenance (SLSA L3) |
|--------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------|----------------------|
| [flux2](https://github.com/fluxcd/flux2)                                             | `docker.io/fluxcd/flux-cli`<br/>`ghcr.io/fluxcd/flux-cli`                                     | `v2.0.0`    | Yes                  |
| [source-controller](https://github.com/fluxcd/source-controller)                     | `docker.io/fluxcd/source-contoller`<br/>`ghcr.io/fluxcd/source-contoller`                     | `v1.0.0`    | Yes                  |
| [kustomize-controller](https://github.com/fluxcd/kustomize-controller)               | `docker.io/fluxcd/kustomize-contoller`<br/>`ghcr.io/fluxcd/kustomize-contoller`               | `v1.0.0`    | Yes                  |
| [notification-controller](https://github.com/fluxcd/notification-controller)         | `docker.io/fluxcd/notification-contoller`<br/>`ghcr.io/fluxcd/notification-contoller`         | `v1.0.0`    | Yes                  |
| [helm-controller](https://github.com/fluxcd/helm-controller)                         | `docker.io/fluxcd/helm-contoller` <br/>`ghcr.io/fluxcd/helm-contoller`                        | `v0.35.0`   | Yes                  |
| [image-reflector-controller](https://github.com/fluxcd/image-reflector-controller)   | `docker.io/fluxcd/image-reflector-contoller`  <br/>`ghcr.io/fluxcd/image-reflector-contoller` | `v0.29.0`   | Yes                  |
| [image-automation-controller](https://github.com/fluxcd/image-automation-controller) | `docker.io/fluxcd/image-automation-contoller`<br/>`ghcr.io/fluxcd/image-automation-contoller` | `v0.35.0`   | Yes                  |

### Example

We will be using the [helm-controller](https://github.com/fluxcd/helm-controller) container
image hosted on GHCR for this example, but these instructions can be used for all Flux container images.

First, we need to find the digest of the image we want to verify:

```console
$ crane digest ghcr.io/fluxcd/helm-controller:v0.34.2
sha256:f97672c005dcfa4d03d76b2fd4063cd9015d9bd088c1c0f50b64e8dba5e37d1e
```

Using the digest, we can now verify the provenance of the Flux controller by specified its repository and version:

```console
$ slsa-verifier verify-image ghcr.io/fluxcd/helm-controller:@sha256:f97672c005dcfa4d03d76b2fd4063cd9015d9bd088c1c0f50b64e8dba5e37d1e --source-uri github.com/fluxcd/helm-controller --source-tag v0.34.2
Verified build using builder https://github.comslsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v1.7.0 at commit 06979867d50edf49ea335fe960cdb9b1d4928a8d
PASSED: Verified SLSA provenance
```

Using Cosign, we can verify the SLSA provenance attestation by specified the workflow and the GitHub OIDC issuer:

```console
$ cosign verify-attestation --type slsaprovenance --certificate-identity-regexp https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v --certificate-oidc-issuer https://token.actions.githubusercontent.com ghcr.io/fluxcd/helm-controller:v0.34.2
Verification for ghcr.io/fluxcd/helm-controller:v0.34.2 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
Certificate subject: https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v1.7.0
Certificate issuer URL: https://token.actions.githubusercontent.com
GitHub Workflow Trigger: push
GitHub Workflow SHA: 06979867d50edf49ea335fe960cdb9b1d4928a8d
GitHub Workflow Name: release
GitHub Workflow Repository: fluxcd/helm-controller
GitHub Workflow Ref: refs/tags/v0.34.2
```
