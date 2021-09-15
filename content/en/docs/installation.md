---
title: "Installation"
linkTitle: "Installation"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
weight: 30
---

This guide walks you through setting up Flux to
manage one or more Kubernetes clusters.

## Prerequisites

You will need a Kubernetes cluster version **1.16** or newer
and kubectl version **1.18** or newer.

## Install the Flux CLI

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded form GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

{{% tabs %}}
{{% tab "Homebrew" %}}

With [Homebrew](https://brew.sh) for macOS and Linux:

```sh
brew install fluxcd/tap/flux
```

{{% /tab %}}
{{% tab "GoFish" %}}

With [GoFish](https://gofi.sh) for Windows, macOS and Linux:

```sh
gofish install flux
```

{{% /tab %}}
{{% tab "bash" %}}

With [Bash](https://www.gnu.org/software/bash/) for macOS and Linux:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash
```

{{% /tab %}}
{{% tab "yay" %}}

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for Arch Linux:

```sh
yay -S flux-bin
```

{{% /tab %}}
{{% tab "nix" %}}

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html) for NixOS:

```sh
nix-env -i fluxcd
```

{{% /tab %}}
{{%  tab "Chocolatey" %}}

With [Chocolatey](https://chocolatey.org/) for Windows:

```powershell
choco install flux
```

{{% /tab %}}
{{% /tabs %}}

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

## Bootstrap

See [Bootstrap](deploy-manage-flux/bootstrap/_index.md) for instructions on how to bootstrap.

## Upgrade

{{% alert color="info" title="Patch versions" %}}
It is safe and advised to use the latest PATCH version when upgrading to a
new MINOR version.
{{% /alert %}}

Update Flux CLI to the latest release with `brew upgrade fluxcd/tap/flux` or by
downloading the binary from [GitHub](https://github.com/fluxcd/flux2/releases).

Verify that you are running the latest version with:

```sh
flux --version
```

### Bootstrap upgrade

If you've used the [bootstrap](#bootstrap) procedure to deploy Flux,
then rerun the bootstrap command for each cluster using the same arguments as before:

```sh
flux bootstrap github \
  --owner=my-github-username \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
```

The above command will clone the repository, it will update the components manifest in
`<path>/flux-system/gotk-components.yaml` and it will push the changes to the remote branch.

Tell Flux to pull the manifests from Git and upgrade itself with:

```sh
flux reconcile source git flux-system
```

Verify that the controllers have been upgrade with:

```sh
flux check
```

{{% alert color="info" title="Automated upgrades" %}}
You can automate the components manifest update with GitHub Actions
and open a PR when there is a new Flux version available.
For more details please see [Flux GitHub Action docs](https://github.com/fluxcd/flux2/tree/main/action).
{{% /alert %}}

### Terraform upgrade

Update the Flux provider to the [latest release](https://github.com/fluxcd/terraform-provider-flux/releases)
and run `terraform apply`.

Tell Flux to upgrade itself in-cluster or wait for it to pull the latest commit from Git:

```sh
kubectl annotate --overwrite gitrepository/flux-system reconcile.fluxcd.io/requestedAt="$(date +%s)"
```

### In-cluster upgrade

If you've installed Flux directly on the cluster, then rerun the install command:

```sh
flux install
```

The above command will  apply the new manifests on your cluster.
You can verify that the controllers have been upgraded to the latest version with `flux check`.

If you've installed Flux directly on the cluster with kubectl,
then rerun the command using the latest manifests from the `main` branch:

```sh
kustomize build https://github.com/fluxcd/flux2/manifests/install?ref=main | kubectl apply -f-
```

## Uninstall

You can uninstall Flux with:

```sh
flux uninstall --namespace=flux-system
```

The above command performs the following operations:

- deletes Flux components (deployments and services)
- deletes Flux network policies
- deletes Flux RBAC (service accounts, cluster roles and cluster role bindings)
- removes the Kubernetes finalizers from Flux custom resources
- deletes Flux custom resource definitions and custom resources
- deletes the namespace where Flux was installed

If you've installed Flux in a namespace that you wish to preserve, you
can skip the namespace deletion with:

```sh
flux uninstall --namespace=infra --keep-namespace
```

{{% alert color="info" title="Reinstall" %}}
Note that the `uninstall` command will not remove any Kubernetes objects
or Helm releases that were reconciled on the cluster by Flux.
It is safe to uninstall Flux and rerun the boostrap, any existing workloads
will not be affected.
{{% /alert %}}
