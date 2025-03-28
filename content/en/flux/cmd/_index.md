---
title: 'Flux CLI'
description: "The Flux Command-Line Interface documentation."
weight: 80
cascade:
  importedDoc: true
---

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded from GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

## Install using package management

{{< tabpane text=true >}}
{{% tab header="macOS" %}}

With [Homebrew](https://brew.sh):

```sh
brew install fluxcd/tap/flux
```

{{% /tab %}}
{{% tab header="Linux" %}}

With [Homebrew](https://brew.sh):

```sh
brew install fluxcd/tap/flux
```

With [yay](https://github.com/Jguer/yay):

```sh
yay -S flux-bin
```

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html):

```sh
nix-env -i fluxcd
```

{{% /tab %}}
{{% tab header="Windows" %}}

With [Chocolatey](https://chocolatey.org/):

```powershell
choco install flux
```

With [winget](https://github.com/microsoft/winget-cli) (only versions after 2.0.0):

```sh
winget install -e --id FluxCD.Flux
```

{{% /tab %}}
{{< /tabpane >}}

## Install using Bash

To install the latest release on Linux, macOS or Windows WSL:

```bash
curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.0.0 bash
```

The [install script](https://raw.githubusercontent.com/fluxcd/flux2/main/install/flux.sh) does the following:
* attempts to detect your OS
* downloads, verifies and unpacks the release tar file in a temporary directory
* copies the `flux` binary to `/usr/local/bin`
* removes the temporary directory

You can also install to a custom directory (e.g., `~/.local/bin`):

```bash
curl -s https://fluxcd.io/install.sh | FLUX_VERSION=2.0.0 bash -s ~/.local/bin
```

Please make sure that this directory is part of your `$PATH` environment variable.

## Install using Docker

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`

Example usage:

```console
$ docker run -it --entrypoint=sh -v ~/.kube/config:/kubeconfig ghcr.io/fluxcd/flux-cli:v2.0.0
/ # flux check --kubeconfig=kubeconfig
```

## Enable shell autocompletion

To configure your shell to load `flux` [bash completions](flux_completion_bash.md) add to your profile:

```sh
. <(flux completion bash)
```

[`zsh`](flux_completion_zsh.md), [`fish`](flux_completion_fish.md),
and [`powershell`](flux_completion_powershell.md)
are also supported with their own sub-commands.

## Install using GitHub Actions

To install the latest release on Linux, macOS or Windows GitHub runners:

```yaml
steps:
  - name: Setup Flux CLI
    uses: fluxcd/flux2/action@main
    with:
      version: 'latest'
  - name: Run Flux CLI
    run: flux version --client
```

For more information please see the [Flux GitHub Action documentation](/flux/flux-gh-action.md).
