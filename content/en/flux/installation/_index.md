---
title: "Installation"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
weight: 30
---

This guide walks you through setting up Flux to
manage one or more Kubernetes clusters.

## Prerequisites

You will need a Kubernetes cluster that matches one of the following versions:

| Kubernetes version | Minimum required |
|--------------------|------------------|
| `v1.24`            | `>= 1.24.0`      |
| `v1.25`            | `>= 1.25.0`      |
| `v1.26`            | `>= 1.26.0`      |
| `v1.27` and later  | `>= 1.27.1`      |

{{% alert color="info" title="Kubernetes EOL" %}}
Note that Flux may work on older versions of Kubernetes e.g. 1.19,
but we don't recommend running [EOL versions](https://endoflife.date/kubernetes)
in production nor do we offer support for these versions.
{{% /alert %}}

## Install the Flux CLI

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded from GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

{{< tabpane text=true >}}
{{% tab header="Homebrew" %}}

With [Homebrew](https://brew.sh) for macOS and Linux:

```sh
brew install fluxcd/tap/flux
```

{{% /tab %}}
{{% tab header="bash" %}}

With [Bash](https://www.gnu.org/software/bash/) for macOS and Linux:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash
```

{{% /tab %}}
{{% tab header="yay" %}}

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for Arch Linux:

```sh
yay -S flux-bin
```

{{% /tab %}}
{{% tab header="nix" %}}

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html) for NixOS:

```sh
nix-env -i fluxcd
```

{{% /tab %}}
{{% tab header="Chocolatey" %}}

With [Chocolatey](https://chocolatey.org/) for Windows:

```powershell
choco install flux
```

{{% /tab %}}
{{< /tabpane >}}

To configure your shell to load `flux` [bash completions](./cmd/flux_completion_bash.md) add to your profile:

```sh
. <(flux completion bash)
```

[`zsh`](./cmd/flux_completion_zsh.md), [`fish`](./cmd/flux_completion_fish.md),
and [`powershell`](./cmd/flux_completion_powershell.md)
are also supported with their own sub-commands.

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`

## Bootstrap with Flux CLI

Using the `flux bootstrap` command you can install Flux on a
Kubernetes cluster and configure it to manage itself from a Git
repository.

If the Flux components are present on the cluster, the bootstrap
command will perform an upgrade if needed. The bootstrap is
idempotent, it's safe to run the command as many times as you want.

The Flux component images are published to DockerHub and GitHub Container Registry
as [multi-arch container images](https://docs.docker.com/docker-for-mac/multi-arch/)
with support for Linux `amd64`, `arm64` and `armv7` (e.g. 32bit Raspberry Pi)
architectures.

If your Git provider is **AWS CodeCommit**, **Azure DevOps**, **Bitbucket Server**, **GitHub** or **GitLab** please
follow the specific bootstrap procedure:

* [AWS CodeCommit](./bootstrap/aws-code-commit.md#flux-installation-for-aws-codecommit)
* [Azure DevOps](./bootstrap/azure.md#flux-installation-for-azure-devops)
* [Bitbucket Server and Data Center](./bootstrap/bitbucket.md#bitbucket-server-and-data-center)
* [GitHub.com and GitHub Enterprise](./bootstrap/github.md#github-and-github-enterprise)
* [GitLab.com and GitLab Enterprise](./bootstrap/gitlab.md#gitlab-and-gitlab-enterprise)

## Bootstrap with Terraform

The bootstrap procedure can be implemented with Terraform using the Flux provider published on
[registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux).
The provider offers a Terraform resource called
[flux_bootstrap_git](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/resources/bootstrap_git)
that can be used to bootstrap Flux in the same way the Flux CLI does it.

Example of Git HTTPS bootstrap:

```hcl
provider "flux" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
  git = {
    url  = var.gitlab_url
    http = {
      username = var.gitlab_user
      password = var.gitlab_token
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path                   = "clusters/my-cluster"
  network_policy         = true
  kustomization_override = file("${path.module}/kustomization.yaml")
}
```

For more details on how to use the Terraform provider
please see the [Flux docs on registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux/latest/docs).

## Customize Flux manifests

You can customize the Flux components before or after running bootstrap.

Assuming you want to customise the Flux controllers before they get deployed on the cluster,
first you'll need to create a Git repository and clone it locally.

Create the file structure required by bootstrap with:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

Add patches to `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1
kind: Kustomization
resources: # manifests generated during bootstrap
  - gotk-components.yaml
  - gotk-sync.yaml

patches: # customize the manifests during bootstrap
  - target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
    patch: |
      # strategic merge or JSON patch
```

Push the changes to main branch:

```sh
git add -A && git commit -m "init flux" && git push
```

And run the bootstrap for `clusters/my-cluster`:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

To make further amendments, pull the changes locally,
edit the `kustomization.yaml` file, push the changes upstream
and rerun bootstrap or let Flux upgrade itself.

Checkout the [bootstrap cheatsheet](../cheatsheets/bootstrap) for various examples of how to customize Flux.

### Multi-tenancy lockdown

Assuming you want to lock down Flux on multi-tenant clusters,
add the following patches to `clusters/my-cluster/flux-system/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --no-cross-namespace-refs=true
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller)"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-remote-bases=true
    target:
      kind: Deployment
      name: "kustomize-controller"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --default-service-account=default
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
  - patch: |
      - op: add
        path: /spec/serviceAccountName
        value: kustomize-controller
    target:
      kind: Kustomization
      name: "flux-system"
```

With the above configuration, Flux will:

- Deny cross-namespace access to Flux custom resources, thus ensuring that a tenant can't use another tenant's sources or subscribe to their events.
- Deny accesses to Kustomize remote bases, thus ensuring all resources refer to local files, meaning only the Flux Sources can affect the cluster-state.
- All `Kustomizations` and `HelmReleases` which don't have `spec.serviceAccountName` specified, will use the `default` account from the tenant's namespace.
  Tenants have to specify a service account in their Flux resources to be able to deploy workloads in their namespaces as the `default` account has no permissions.
- The flux-system `Kustomization` is set to reconcile under a service account with cluster-admin role,
  allowing platform admins to configure cluster-wide resources and provision the tenant's namespaces, service accounts and RBAC.

To apply these patches, push the changes to the main branch and run `flux bootstrap`.

## Dev install

For testing purposes you can install Flux without storing its manifests in a Git repository:

```sh
flux install
```

Or using kubectl:

```sh
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

Then you can register Git repositories and reconcile them on your cluster:

```sh
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --tag-semver=">=4.0.0" \
  --interval=1m

flux create kustomization podinfo-default \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/podinfo.default" \
  --health-check-timeout=2m \
  --target-namespace=default
```

You can register Helm repositories and create Helm releases:

```sh
flux create source helm bitnami \
  --interval=1h \
  --url=https://charts.bitnami.com/bitnami

flux create helmrelease nginx \
  --interval=1h \
  --release-name=nginx-ingress-controller \
  --target-namespace=kube-system \
  --source=HelmRepository/bitnami \
  --chart=nginx-ingress-controller \
  --chart-version="5.x.x"
```
