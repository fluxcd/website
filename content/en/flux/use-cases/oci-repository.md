---
title: Flux with OCI Repositories
linkTitle: OCI Repository
description: "Deploy Kubernetes manifests and Helm charts from OCI-compliant container registries with Flux."
weight: 35
---

## Why use OCIRepository?

With `OCIRepository`, Flux can pull Kubernetes manifests and Helm charts directly from
OCI-compliant container registries. This enables a *Gitless GitOps* workflow where the
desired cluster state is distributed and reconciled entirely through OCI artifacts, removing
the Git server as a production dependency.

`OCIRepository` is ideal when:

- Manifests are generated in CI (e.g. from [cuelang](https://cuelang.org/),
  [jsonnet](https://jsonnet.org/), or [Helm template](https://helm.sh/)) and should not be
  stored in Git.
- You want to co-locate application images and deployment manifests in the same registry.
- You need deterministic deployments pinned by digest or semver.
- You want to verify artifact signatures with [Cosign or Notation](/flux/cheatsheets/oci-artifacts/#signing-and-verification)
  before reconciliation.

For the full set of publishing, tagging, and CI automation workflows, see the
[OCI Artifacts Cheatsheet](/flux/cheatsheets/oci-artifacts/).

## Prerequisites

To follow this guide you'll need a Kubernetes cluster with the GitOps
toolkit controllers installed on it.
Please see the [get started guide](/flux/get-started/)
or the [installation guide](/flux/installation/).

## Reconciling plain manifests with Kustomization

You can package your Kubernetes manifests as an OCI artifact and use an `OCIRepository`
together with a `Kustomization` to reconcile them on the cluster. The source-controller
will pull the artifact on an interval and make it available to the kustomize-controller.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    tag: latest
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  targetNamespace: default
  prune: true
  sourceRef:
    kind: OCIRepository
    name: podinfo
  path: ./
```

Whenever a new artifact is pushed to the registry with the `latest` tag, the
`OCIRepository` detects the change and the `Kustomization` reconciles the new
manifests automatically.

{{% alert color="info" title="Pinning versions" %}}
Using `tag: latest` is convenient for development. In production, prefer `semver` or `digest`
selectors for deterministic deployments. See the [`OCIRepository` CRD docs](/flux/components/source/ocirepositories/)
for all available reference strategies.
{{% /alert %}}

## Releasing Helm charts with HelmRelease

Helm charts stored in OCI registries can be consumed by declaring an `OCIRepository`
and referencing it from a `HelmRelease` via `chartRef`. The source-controller fetches
the chart artifact and exposes it to the helm-controller.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  url: oci://ghcr.io/stefanprodan/charts/podinfo
  layerSelector:
    mediaType: "application/vnd.cncf.helm.chart.content.v1.tar+gzip"
    operation: copy
  ref:
    semver: ">=6.9.0"
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  releaseName: podinfo
  chartRef:
    kind: OCIRepository
    name: podinfo
  values:
    replicaCount: 2
```

The `layerSelector` configures the `OCIRepository` to extract the Helm chart layer
from the multi-layer OCI artifact. The `ref` field supports `tag`, `digest`, or
`semver` selectors so that releases can be pinned or automatically upgraded.

{{% alert color="info" title="Authentication" %}}
HTTP/S authentication and contextual login can be configured for private
OCI registries. See the [`OCIRepository` CRD docs](/flux/components/source/ocirepositories/) for more details
## Next Steps

- [OCI Artifacts Cheatsheet](/flux/cheatsheets/oci-artifacts/) — publishing, authentication, signing, and automation workflows
- [`OCIRepository` CRD Documentation](/flux/components/source/ocirepositories/) — full API reference
- [Manage Helm Releases Guide](/flux/guides/helmreleases/) — HelmRelease configuration including OCI sources
{{% /alert %}}

## Combining both artifact types

The two artifact types can be used together. For example, you can bundle a `Namespace`,
an `OCIRepository`, and a `HelmRelease` into a single Flux OCI artifact. The `Kustomization`
applies the namespace and the `OCIRepository` source, and the `HelmRelease` installs
the chart — all pulled from the same registry.

This pattern is covered in detail in the [OCI Artifacts Cheatsheet](/flux/cheatsheets/oci-artifacts/#helm-oci).

## Verification

Flux supports verifying OCI artifacts signed with [Sigstore Cosign](https://github.com/sigstore/cosign)
or [Notaryproject Notation](https://github.com/notaryproject/notation) before downloading
and reconciling them. Add a `verify` section to the `OCIRepository` spec:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    semver: "*"
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
```

If verification fails, Flux will not fetch the artifact and will emit an alert.
See the [signing and verification guide](/flux/cheatsheets/oci-artifacts/#signing-and-verification)
for complete setup instructions.

## Next Steps

- [OCI Artifacts Cheatsheet](/flux/cheatsheets/oci-artifacts/) — publishing, authentication, signing, and automation workflows
- [`OCIRepository` CRD Documentation](/flux/components/source/ocirepositories/) — full API reference
- [Manage Helm Releases Guide](/flux/guides/helmreleases/) — HelmRelease configuration including OCI sources