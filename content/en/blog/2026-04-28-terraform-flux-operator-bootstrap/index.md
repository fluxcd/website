---
author: Matheus Pimenta
date: 2026-04-28 09:00:00+00:00
title: Bootstrapping Flux with Terraform, the right way
description: "A Terraform module that bootstraps Flux Operator without fighting Flux for resource ownership, keeps secrets out of state, runs in the same root module as the cluster, and handles platform prerequisites that Flux itself depends on."
url: /blog/2026/04/terraform-flux-operator-bootstrap/
tags: [ecosystem]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

![](featured-image.png)

This post introduces a new
[Terraform module](https://github.com/controlplaneio-fluxcd/terraform-kubernetes-flux-operator-bootstrap)
(fully compatible with OpenTofu) that bootstraps [Flux Operator](https://fluxoperator.dev)
into a Kubernetes cluster and then steps aside, letting Flux do what Flux does best.

Here are some of the problems it sets out to fix.

## Ownership handoff

Terraform is the natural place to install Flux right after a cluster comes up, since
credentials are in scope and providers are wired. But once Flux is online, every
object Terraform applied is now also an object Flux wants to reconcile. The traditional
workarounds (the [`fluxcd/flux`](https://registry.terraform.io/providers/fluxcd/flux/latest)
provider, or chained `helm_release` resources) keep Terraform on the hook for
steady-state reconciliation forever.

This module takes a different approach. Terraform owns only the bootstrap mechanism: a
namespace, temporary RBAC, and a Kubernetes Job that applies Flux Operator
and the [FluxInstance](https://fluxoperator.dev/docs/crd/fluxinstance/).
The module implements a **create-if-missing** strategy. Flux adopts the resources and
Terraform stops touching it. When inputs are unchanged, `terraform plan`
shows zero diff.

## Using one GitOps repository

The Terraform root module and the Flux manifests live side-by-side in the same repository,
so the bootstrap inputs and the steady-state desired state are versioned together:

```text
repo/
├── terraform/                             # Terraform root module
│   ├── main.tf
│   ├── providers.tf
│   └── variables.tf
└── clusters/
    └── staging/                           # reconciled by Flux via FluxInstance.spec.sync.path
        └── flux-system/
            ├── flux-instance.yaml         # applied by the bootstrap Job
            ├── flux-operator-values.yaml  # shared between Terraform and the Flux-managed HelmRelease
            ├── flux-operator.yaml         # ResourceSet wrapping the Flux Operator HelmRelease
            ├── runtime-info.yaml          # Git-managed fields of flux-runtime-info (optional)
            └── kustomization.yaml         # configMapGenerator for flux-operator-values
```

The Terraform module loads the same `flux-instance.yaml` that Flux will reconcile after
bootstrap and provisions the Git pull secret it needs to keep syncing the repository:

```hcl
module "flux_operator_bootstrap" {
  source   = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"
  revision = 1

  gitops_resources = {
    instance_yaml = file("${path.root}/../clusters/${var.cluster_name}/flux-system/flux-instance.yaml")
  }

  managed_resources = {
    secrets_yaml = <<-YAML
      apiVersion: v1
      kind: Secret
      metadata:
        name: flux-system
      type: Opaque
      stringData:
        username: git
        password: '${var.git_token}'
    YAML
  }
}
```

No secret material ever lands in the Terraform state file. The
module marks `managed_resources` as `sensitive` and only persists a SHA-256 hash to
detect changes, while still reconciling drift on every run with server-side apply - the
same model as kustomize-controller. Pull values from Vault, AWS Secrets Manager, or any
other store via `data` sources and compose them into `secrets_yaml`; the rendered YAML
never appears in state.

## No two-phase apply

The module does not require cluster connectivity at plan time.
Because the configuration is static, it can live in the same Terraform root
module that creates the cluster.
Since the plan doesn't need runtime information, the operator bootstrap can directly `depends_on` the cluster module instance:

```hcl
module "cluster" { source = "..." }

provider "helm" {
  kubernetes = {
    host                   = module.cluster.endpoint
    cluster_ca_certificate = base64decode(module.cluster.ca_certificate)
    token                  = module.cluster.token
  }
}

module "flux_operator_bootstrap" {
  depends_on = [module.cluster]
  source     = "controlplaneio-fluxcd/flux-operator-bootstrap/kubernetes"
  revision   = 1
  # ...
}
```

## Flux's own dependencies: CNI and Storage

Some components have to exist before Flux can run (a self-managed CNI like Cilium is
a good example). Without a CNI, pods lack network access, and this includes the Flux
controllers themselves. The new Terraform module accepts an ordered list of prerequisite
Helm charts and manifests, which are applied in sequence by the bootstrap Job before
Flux Operator. For the CNI scenario, we let the Job run with `host_network: true`,
since pod networking is unavailable until after the CNI comes up:

```hcl
job = {
  host_network = true
}

gitops_resources = {
  instance_yaml = file("${path.root}/../clusters/${var.cluster_name}/flux-system/flux-instance.yaml")
  prerequisites = {
    charts = [
      { name = "cilium", repository = "quay.io/cilium/charts/cilium", namespace = "kube-system" },
    ]
  }
}
```

This extends to any component your Flux install depends on.
The same mechanism can handle CSI drivers that the Flux controllers may need to mount before
they can start. This lays the groundwork for an upcoming SPIFFE/SPIRE integration that
we'll have more to share about in the next few releases.
Any of these components then become adopted by Flux for steady-state reconciliation,
following the same handoff described above that's used for the Flux Operator HelmRelease
and FluxInstance.

This module bootstraps Flux Operator without fighting Flux
for resource ownership. It keeps secrets out of the state file, runs in the same root module
as the cluster itself, and bootstraps platform prerequisites like CNI and CSI that Flux itself
depends on before handing management of those add-ons back to Flux.

## Migrating

- From the [`fluxcd/flux`](https://registry.terraform.io/providers/fluxcd/flux/latest) provider - [migration guide](https://github.com/controlplaneio-fluxcd/terraform-kubernetes-flux-operator-bootstrap/blob/main/docs/migration-from-flux-provider.md)
- From the previous flux-operator Terraform example - [migration guide](https://github.com/controlplaneio-fluxcd/terraform-kubernetes-flux-operator-bootstrap/blob/main/docs/migration-from-previous-approach.md)
- Minimal example - [flux-operator/config/terraform](https://github.com/controlplaneio-fluxcd/flux-operator/tree/main/config/terraform)
- Full reference setup - [d2-fleet](https://github.com/controlplaneio-fluxcd/d2-fleet/tree/main/terraform)
