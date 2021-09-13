---
title: "Install the Flux CLI"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
no_list: true
weight: 41
---

The Flux command-line tool, flux , allows you to 

- Bootstrap Flux onto a cluster
- Generate Flux resource definitions
- Monitor flux components and resources

For more information including a complete list of flux operations, see the [`flux` reference documentation](../../cmd/_index.md).

The Flux CLI is installable on a variety of Linux platforms, macOS and Windows. Find your preferred operating system below.

- [Install the Flux CLI on Linux](linux.md)
- [Install the Flux CLI on macOS](osx.md)
- [Install the Flux CLI on Windows](windows.md)

## Binaries

The Flux CLI is available as a binary executable for all major platforms. Binaries can be downloaded from GitHub
[releases page](https://github.com/fluxcd/flux2/releases). 

Links to the binaries for the latest release are provided below.

{{< readFile file="static/snippet/docs/latestrelease.md" markdown="true" >}}


## Container Image

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`
