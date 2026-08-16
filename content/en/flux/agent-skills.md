---
title: "Flux AI Agent Skills"
linkTitle: "Flux Agent Skills"
description: "AI skills for generating Kubernetes manifests, auditing GitOps repositories, and debugging live clusters."
weight: 145
---

The Flux project maintains a collection of reusable skills that give AI Agents expertise in Flux CD,
Kubernetes, and GitOps best practices for generating manifests, answering Flux questions,
auditing repository structure, security, operational readiness, and debugging live cluster installations.

The [Flux Skills](https://github.com/fluxcd/agent-skills) bundle curated reference docs written
by the maintainers, OpenAPI schemas and executable scripts that ground the agent's claims
in deterministic tool output.

The three skills are designed to work together, and the agent picks the
right one based on context: `gitops-knowledge` for questions and manifest
generation, `gitops-repo-audit` for validating and auditing repository
contents, and `gitops-cluster-debug` for troubleshooting live clusters.

## gitops-knowledge

This skill turns the agent into a Flux CD and [Flux Operator](https://fluxoperator.dev/) expert.
It answers questions about GitOps concepts and generates YAML for all Flux
custom resources, from HelmRelease and Kustomization to ResourceSets,
image automation, and notifications.

The skill encodes the decision trees a Flux maintainer would walk through:
which source type fits which delivery model, when to use a ResourceSet
instead of a Kustomization, how to choose between Git-based and Gitless
image automation. It also carries the canonical YAML patterns and a list
of the mistakes agents make most often, like using Go template delimiters
in ResourceSets or setting mutually exclusive HelmRelease fields.

Before generating YAML for any custom resource, the agent reads the
bundled OpenAPI schema to verify exact field names, types, and enum
values. After writing manifests, it validates them with
[Flux Schema](/flux/cli-plugins/flux-schema/) and fixes any
violations before showing you the result. The generate-validate-fix loop
means the YAML you get has already passed the same checks the Kubernetes
API server would apply.

Example prompts:

```text
What's the recommended GitOps structure for a multi-cluster fleet?
```

```text
Generate a HelmRelease for oci://ghcr.io/my-org/frontend,
and a Kustomization to deploy it in the staging cluster.
```

```text
How do I set up preview environments for pull requests with Flux Operator?
```

The skill works best inside a GitOps repository that contains an
`AGENTS.md` describing your organization's structure,
cluster topology, and secret management approach. The agent combines the
skill's reference files with the repository context to generate manifests
tailored to your setup.

## gitops-repo-audit

This skill turns the agent into a GitOps repository auditor. It works
entirely on local files (no cluster access needed) and walks through six
phases: discovery, manifest validation, API compliance, best practices
assessment, security review, and a final report with recommendations
prioritized by severity.

Each phase is grounded in deterministic tooling rather than the agent's
own reading of the files. Discovery runs `flux schema discover` to build a
structured inventory of directories, resources, and Flux objects.
Validation runs `flux schema validate` on both raw manifests and rendered
overlays. API compliance runs `flux migrate --dry-run` to pinpoint
deprecated API versions with exact file paths and line numbers. The best
practices and security phases then work from maintainer-written checklists
covering RBAC, multi-tenancy, secrets management, source authentication,
and supply chain security.

To run a full audit, ask:

```text
Audit the current repo and provide a GitOps report.
```

In Claude Code, you can also invoke the skill directly with
`/gitops-repo-audit`. Targeted prompts work too: you can validate the repo
without a full audit, or audit only the files with changes, which makes
the skill useful as a pre-push check during day-to-day work.

For larger setups, the repository includes a
[Claude Code guide](https://github.com/fluxcd/agent-skills/blob/main/docs/claude-agent-setup.md)
for orchestrating Flux sub-agents that audit multiple repositories
(fleet, infra, and apps repos) and aggregate the results into an
HTML report.

## gitops-cluster-debug

This skill turns the agent into a Flux troubleshooter for live Kubernetes
clusters. It connects through the
[Flux MCP server](https://fluxoperator.dev/mcp-server/) and follows the
same debugging playbooks the maintainers use: check the Flux installation
health, trace a failing HelmRelease or Kustomization from its source
through to the managed workloads, analyze controller and pod logs, and
walk dependency chains to find the actual root cause instead of the
symptom.

The skill ships dedicated workflows for the failures users hit most:
sources stuck on fetch failed, image automation not committing tag
updates, alerts not being delivered, and ResourceSets with failing input
providers. The result is a root cause analysis report with the dependency
chain, the evidence from status conditions and logs, and prioritized
remediation steps.

Example prompts:

```text
Check the Flux installation on my current cluster.
```

```text
Debug the failing HelmRelease podinfo in the apps namespace.
```

```text
Troubleshoot the Kustomization flux-system/infra-controllers in the staging cluster.
```

The MCP server can be configured in Claude Code with:

```bash
claude mcp add --scope user --transport stdio flux-operator-mcp \
  --env KUBECONFIG=$HOME/.kube/config \
  -- flux-operator-mcp serve --read-only
```

With the `--read-only` flag, the agent can inspect but not mutate the
cluster. The MCP server also masks Kubernetes Secrets, so the agent sees
only the data key names, never the values.

## Getting Started

The recommended installation method is the Flux Operator CLI, which
verifies the cosign signature of the OCI artifact, confirming it was
published by the Flux team:

```shell
flux plugin install operator
```

Then, from the root of your GitOps repository:

```shell
flux operator skills install ghcr.io/fluxcd/agent-skills --agent claude-code
```

This extracts the skills to `.agents/skills` and creates per-skill
symlinks for the chosen agent. If your agent supports the conventional
`.agents/skills` path, you can omit the `--agent` flag. To update the
skills later, run `flux operator skills update`.

For Claude Code and Codex you can also install straight from the plugin
marketplace:

```text
/plugin marketplace add fluxcd/agent-skills
/plugin install gitops-skills@fluxcd
```

Or with Vercel's skills tool, which works across agents:

```shell
npx skills add fluxcd/agent-skills
```

The skills rely on a few CLIs being available in the environment: `flux`,
`flux-schema` (install with `flux plugin install schema`), `kustomize` or
`kubectl`, and `flux-operator-mcp` for the cluster debugging skill. A
[Brewfile](https://raw.githubusercontent.com/fluxcd/agent-skills/refs/heads/main/Brewfile)
is provided for easy installation on macOS and Linux.
