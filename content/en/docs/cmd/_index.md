---
title: 'Flux CLI'
description: "The Flux Command-Line Interface documentation."
weight: 80
---

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded form GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

## Installation

With Homebrew:

```sh
brew install fluxcd/tap/flux
```

With Bash:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash

# enable Bash completions
echo ". <(flux completion bash)" >> ~/.bash_profile
```

Arch Linux (AUR) packages:

- [flux-bin](https://aur.archlinux.org/packages/flux-bin): install the latest
  stable version using a pre-build binary (recommended)
- [flux-go](https://aur.archlinux.org/packages/flux-go): build the latest
  stable version from source code
- [flux-scm](https://aur.archlinux.org/packages/flux-scm): build the latest
  (unstable) version from source code from our git `main` branch

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`
