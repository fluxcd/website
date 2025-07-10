---
title: "Flux installation"
linkTitle: "Installation"
description: "How to install the Flux CLI and the Flux controllers."
weight: 30
---

The Flux project is comprised of a command-line tool (the Flux CLI) and a series
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
| `v1.31`            | `>= 1.31.0`      |
| `v1.32`            | `>= 1.32.0`      |
| `v1.33` and later  | `>= 1.33.0`      |

{{% alert color="info" title="Kubernetes EOL" %}}
Note that Flux may work on older versions of Kubernetes e.g. 1.29,
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

The recommended way of installing Flux on Kubernetes clusters is by using the bootstrap procedure.

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
* [Oracle Cloud Git Repositories](./bootstrap/oracle-cloud-git-repositories.md)

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

Check out the examples available for the provider in the
[fluxcd/terraform-provider-flux](https://github.com/fluxcd/terraform-provider-flux) repository.

### Bootstrap with Flux Operator

The [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator) is an open-source project
part of the [Flux ecosystem](/ecosystem/#flux-extensions) that provides a declarative API for the
lifecycle management of the Flux controllers.

The operator offers an alternative to the Flux CLI bootstrap procedure, with the option to configure the
reconciliation of the cluster state from Git repositories, OCI Artifacts, or S3-compatible storage.

#### Install the Flux Operator

Install the Flux Operator in the `flux-system` namespace, for example, using Helm:

```shell
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

The Flux Operator can be installed using Helm, Terraform, OpenTofu, OperatorHub, and other methods.
For more information, refer to the [installation guide](https://fluxcd.control-plane.io/operator/install/).

#### Configure the Flux Instance

Create a [FluxInstance](https://fluxcd.control-plane.io/operator/fluxinstance/) resource
named `flux` in the `flux-system` namespace to install the latest Flux stable version and configure the
Flux controllers to sync the cluster state from an OCI artifact stored in GitHub Container Registry:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "1h"
    fluxcd.controlplane.io/reconcileTimeout: "5m"
spec:
  distribution:
    version: "2.x"
    registry: "ghcr.io/fluxcd"
    artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
    - image-reflector-controller
    - image-automation-controller
  cluster:
    type: kubernetes
    multitenant: false
    networkPolicy: true
    domain: "cluster.local"
  kustomize:
    patches:
      - target:
          kind: Deployment
          name: "(kustomize-controller|helm-controller)"
        patch: |
          - op: add
            path: /spec/template/spec/containers/0/args/-
            value: --concurrent=10
          - op: add
            path: /spec/template/spec/containers/0/args/-
            value: --requeue-dependency=5s
  sync:
    kind: OCIRepository
    url: "oci://ghcr.io/my-org/my-fleet-manifests"
    ref: "latest"
    path: "clusters/my-cluster"
    pullSecret: "ghcr-auth"
```

> For more information on how to configure syncing from Git repositories,
> container registries, and S3-compatible storage, refer to the
> [cluster sync guide](https://fluxcd.control-plane.io/operator/flux-sync/).

The operator can automatically upgrade the Flux controllers and their CRDs when a new version is available.
To restrict the upgrade to patch versions only, set the `distribution.version` field to e.g. `2.6.x`
or to a fixed version e.g. `2.6.0` to disable automatic upgrades.

The Flux Operator can take over the management of existing installations from the Flux CLI or other tools.
For a step-by-step guide, refer to the [Flux Operator migration guide](https://fluxcd.control-plane.io/operator/).

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
helm install -n flux-system --create-namespace flux oci://ghcr.io/fluxcd-community/charts/flux2
```

{{% alert color="danger" title="Helm support" %}}
Please note that the Helm charts are maintained by
the [fluxcd-community](https://github.com/fluxcd-community/helm-charts) on
a best effort basis with no guarantees around release cadence.
{{% /alert %}}
