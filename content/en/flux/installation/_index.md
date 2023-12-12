---
title: "Flux installation"
linkTitle: "Installation"
description: "How to install the Flux CLI and the Flux controllers."
weight: 30
---

The Flux project is comprised of a command-line tool (the FLux CLI) and a series
of [Kubernetes controllers](/flux/components/).

To install Flux, first you'll need to download the `flux` CLI.
Then using the CLI, you can deploy the Flux controllers on your clusters
and configure your first GitOps delivery pipeline.

## Prerequisites

The person performing the Flux installation must have
**cluster admin rights** for the target Kubernetes cluster.

The Kubernetes cluster should match one of the following versions:

| Kubernetes version | Minimum required |
|--------------------|------------------|
| `v1.26`            | `>= 1.26.0`      |
| `v1.27`            | `>= 1.27.1`      |
| `v1.28` and later  | `>= 1.28.0`      |

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

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for
Arch Linux:

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

To configure your shell to load `flux` [bash completions](/flux/cmd/flux_completion_bash/) add to your profile:

```sh
. <(flux completion bash)
```

[`zsh`](/flux/cmd/flux_completion_zsh/), [`fish`](/flux/cmd/flux_completion_fish/),
and [`powershell`](/flux/cmd/flux_completion_powershell/)
are also supported with their own sub-commands.

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`

## Install the Flux controllers

The recommend way of installing Flux on Kubernetes clusters is by using the bootstrap procedure.

### Bootstrap with Flux CLI

The `flux bootstrap` command deploys the Flux controllers on Kubernetes cluster(s)
and configures the controllers to sync the cluster(s) state from a Git repository.
Besides installing the controllers, the bootstrap command pushes the Flux manifests
to the Git repository and configures Flux to update itself from Git.

![bootstrap](/flux/img/flux-bootstrap-diagram.png)

If the Flux controllers are present on the cluster, the bootstrap command will perform
an upgrade if needed. Bootstrap is idempotent, it's safe to run the command as many times as you want.

After running the bootstrap command, any operation on the cluster(s) (including Flux upgrades)
can be done via Git push, without the need to connect to the Kubernetes API.

#### Bootstrap providers

Flux integrates with popular Git providers to simplify the
initial setup of deploy keys and other authentication mechanisms:

* [GitHub](./bootstrap/github.md)
* [GitLab](./bootstrap/gitlab.md)
* [Bitbucket](./bootstrap/bitbucket.md)
* [AWS CodeCommit](./bootstrap/aws-codecommit.md)
* [Azure DevOps](./bootstrap/azure-devops.md)
* [Google Cloud Source](./bootstrap/google-cloud-source.md)

If your Git provider is not in the above list,
please follow the [generic bootstrap procedure](./bootstrap/generic-git-server.md)
which works with any Git server.

#### Bootstrap configuration

Various configuration options are available at bootstrap time such as:

* [Installing optional components](configuration/optional-components.md)
* [Enforcing tenant isolation on shared clusters](configuration/multitenancy.md)
* [Using workload identity on AWS, Azure and GCP](configuration/workload-identity.md)

Please see the [bootstrap configuration](configuration/_index.md) section for more examples
on how to customize Flux.

### Bootstrap with Terraform

The bootstrap procedure can be implemented with Terraform using the Flux provider published on
[registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux).

The provider offers a Terraform resource called
[flux_bootstrap_git](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/resources/bootstrap_git)
that can be used to bootstrap Flux in the same way the Flux CLI does it.

For more details on how to use the Terraform provider
please see the [Flux docs on registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux/latest/docs).

### Dev install

For testing purposes you can install the Flux controllers
without storing their manifests in a Git repository.

Install with `flux`:

```sh
flux install
```

Install with `kubectl`:

```sh
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

Install with `helm`:

```sh
helm install -n flux-system flux oci://ghcr.io/fluxcd-community/charts/flux2
```

{{% alert color="danger" title="Helm support" %}}
Please note that the Helm charts are maintained by
the [fluxcd-community](https://github.com/fluxcd-community/helm-charts) on
a best effort basis with no guarantees around release cadence.
{{% /alert %}}
