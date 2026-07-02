---
author: Stefan Prodan
date: 2026-07-20 10:00:00+00:00
title: Introducing Flux Schema
description: "Static validation for GitOps workflows with Kubernetes API server semantics, built for CI pipelines and AI agents."
url: /blog/2026/07/flux-schema-validation/
tags: [announcement]
resources:
  - src: "**.{png,jpg}"
    title: "Image #:counter"
---

In this blog post, we introduce [Flux Schema](https://github.com/fluxcd/flux-schema),
a new Flux CLI plugin for validating Kubernetes manifests against JSON Schema
and CEL rules using the same evaluation semantics as the Kubernetes API server.
It ships as a single Go binary with a built-in catalog covering Kubernetes,
OpenShift, Gateway API, and the Flux ecosystem CRDs.

![](featured-image.png)

Flux Schema brings static validation to GitOps workflows. Platform engineers
can catch invalid definitions in pull requests before Flux reconciles them on
clusters, and AI agents get a deterministic feedback loop for verifying the
Kubernetes and Flux manifests they generate.

## Why Another Validation Tool

The GitOps workflow has a well-known blind spot: a manifest with a typo, a wrong
type, or a violated CEL rule sails through `git push` and only fails when
Flux applies it on the cluster. By then the error lives in your main
branch and shows up as a failed reconciliation instead of a failed pull request.

Tools like `kubeconform` (which inspired this project) solved part of the problem
by validating manifests against JSON Schemas offline. Flux Schema builds on that
idea and extends it with the API server's own evaluation semantics:

- **Strict schema validation**: every field of every Kubernetes built-in kind
  and custom resource is checked. Unknown fields, wrong types, and missing
  required properties are reported as schema violations.
- **CEL evaluation**: the `x-kubernetes-validations` rules embedded in CRDs are
  evaluated with the same engine as the Kubernetes API server. A HelmRelease
  missing both `chart` and `chartRef` is caught locally, not on the cluster.
- **Strict YAML decoding**: duplicate keys are rejected, matching Flux behavior,
  and metadata names, namespaces, labels, and annotations are checked against
  API server rules (DNS-1123, qualified names).
- **Built-in catalog**: JSON Schemas with CEL rules for Kubernetes, OpenShift,
  Gateway API, Flux, Flagger, and Flux Operator CRDs, refreshed automatically
  from upstream stable releases.
- **SOPS-aware**: the SOPS metadata fields can be stripped before validation,
  so encrypted Secrets are checked without decryption.

## Getting Started

Install the plugin with the Flux CLI:

```shell
flux plugin install schema
```

Validate a directory tree against the built-in catalog:

```shell
flux schema validate ./manifests
```

You can also validate rendered kustomize overlays and Helm charts, the same
manifests Flux sees at reconciliation time:

```shell
kustomize build ./clusters/production | flux schema validate --verbose

helm template ./charts/app | flux schema validate -v --skip-missing-schemas
```

The output pinpoints each violation with its JSON path, ready to act on:

```console
$ flux schema validate ./manifests

manifests/releases.yaml - HelmRelease/apps/frontend is invalid: cel violation
  - /spec: Invalid value: either 'chart' or 'chartRef' must be set
manifests/sources.yaml - Bucket/apps/frontend-config is invalid: schema violation
  - /spec: missing property 'bucketName'
  - /spec/interval: got number, want string
  - /spec: additional properties 'force' not allowed
Summary: 5 resources found in 2 files - Valid: 3, Invalid: 2, Skipped: 0
```

By default, only the invalid documents are printed; pass `--verbose` to also
list the valid and skipped ones.

For third-party CRDs not in the built-in catalog, you can layer additional
schema locations, or extract JSON Schemas straight from your cluster:

```shell
kubectl get crds -o yaml | flux schema extract crd -d ./my-catalog

flux schema validate ./manifests \
  --schema-location ./my-catalog \
  --schema-location default
```

## Shifting Validation Left in CI

Running Flux Schema in CI catches violations in pull requests before they
reach the cluster. For GitHub repositories, two composite actions cover the
whole pipeline: one installs the CLI, the other detects kustomize overlays
and Helm charts, renders them, and validates every document against the
catalog.

```yaml
name: flux-schema

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7
      - name: Setup Flux with Schema plugin
        uses: fluxcd/flux2/action@main
        with:
          plugins: |
            schema
      - name: Validate manifests
        uses: fluxcd/flux-schema/actions/validate@main
        with:
          helm-charts: "true"
```

For other CI systems and air-gapped environments, the
`ghcr.io/fluxcd/flux-schema` container image bundles the entire catalog,
so validation runs without network access. A `.fluxschema.yml` file makes
the validation config reproducible across local machines and CI.

## A Feedback Loop for AI Agents

The second audience for Flux Schema is AI agents. Anyone who has asked an AI
assistant to generate Flux manifests knows the failure mode: the YAML looks
plausible, the field names are almost right, and the error only surfaces when
the manifest hits the cluster.

Agents thrive when they can verify their own work. For code, that feedback
loop is the compiler and the test suite. For Kubernetes manifests, the only
authoritative validator was the API server, so agents either applied manifests
to a live cluster (slow, risky, requires credentials) or skipped verification
entirely.

Flux Schema gives agents the API server's judgment as a local, read-only,
instant operation. The agent generates a manifest, runs `flux schema validate`,
reads the violations with their JSON paths, fixes them, and repeats until the
output is clean. Structured reports in JSON or YAML make the results
machine-parseable:

```shell
flux schema validate ./manifests -o json
```

Because the catalog is refreshed automatically from upstream releases, agents
validate against the current APIs rather than the versions frozen into their
training data.

## Repository Discovery for Agents

Validation is only half of what an agent needs. Before generating or auditing
anything, an agent has to understand the repository it landed in, and GitOps
repos are hostile to `tree` and `grep` exploration: file names like
`sync.yaml` and `release.yaml` reveal nothing, multi-document files hide
resources, and grepping for `kind: HelmRelease` matches kustomize patch
files.

The `flux schema discover` command replaces that read-and-grep loop with one
deterministic pass:

```shell
flux schema discover ./my-gitops-repo -o json
```

The scan is purely static (no kustomize builds, no Helm rendering, no cluster
access) and emits a structured inventory designed for AI agents:

- **Directory classification**: every directory is typed as plain Kubernetes
  manifests, a kustomize overlay, a Helm chart, or a Terraform module, so the
  repository pattern reads at a glance.
- **Flux resources by file**: every Flux resource is listed with its defining
  file and `namespace/name` identity, so an agent opens exactly the files
  relevant to the task.
- **Resource census by API version**: everything is counted per
  `apiVersion/Kind`, so deprecated API versions stand out without reading a
  single manifest.
- **Context-budgeted output**: plain Kubernetes resources appear as counts
  (2,000 Deployments cost a few lines, not thousands), and Helm chart and
  Terraform subtrees are pruned. A typical repository inventories in a few KB.

Like the validation report, the inventory is a versioned JSON envelope with a
published schema, so agents parse it programmatically instead of interpreting
ad-hoc shell output.

## Powering the Flux AI Skills

Flux Schema is the engine behind the official
[GitOps Agent Skills](https://github.com/fluxcd/agent-skills)
developed by the Flux maintainers.

The `gitops-repo-audit` skill turns an AI assistant into a GitOps repository
auditor. Its discovery phase runs `flux schema discover` to build the
inventory, and its validation phase runs `flux schema validate` on both raw
manifests and rendered kustomize output. The skill also ships the Flux OpenAPI
schemas, so the agent verifies exact field names before recommending any YAML
change instead of guessing from memory.

You can install the skills in your GitOps repository with the Flux Operator
CLI, which verifies the cosign signature of the OCI artifact:

```shell
flux plugin install operator

flux operator skills install ghcr.io/fluxcd/agent-skills
```

For Claude Code and Codex you can install from the marketplace:

```text
/plugin marketplace add fluxcd/agent-skills
/plugin install gitops-skills@fluxcd
```

Then ask your assistant to "audit this GitOps repo" and watch it work through
discovery, validation, API compliance, best practices, and security review,
with every claim grounded in the flux-schema output rather than hallucinated.

## What's Next

Flux Schema is Apache 2.0 licensed and developed in the open at
[fluxcd/flux-schema](https://github.com/fluxcd/flux-schema). The
[documentation](/flux/cli-plugins/flux-schema/) covers
manifest validation, custom catalogs, repository discovery, and the JSON
Schema references for all output formats.

Whether you wire it into your CI pipeline, run it locally before pushing, or
hand it to an AI agent as its ground truth, the goal is the same: find out
that a manifest is broken before Flux does. Give it a try and let us know what
you think by opening issues or discussions on GitHub.
