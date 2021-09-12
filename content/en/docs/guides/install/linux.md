---
title: "Install the Flux CLI on Linux"
linkTitle: "Install the Flux CLI on Linux"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
---

## Install using package management

{{% tabs %}}
{{% tab "Homebrew" %}}

  {{< readFile file="static/snippet/docs/install/homebrew.md" markdown="true" >}}

{{% /tab %}}
{{% tab "yay" %}}

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for Arch Linux:

```sh
yay -S flux-bin
```

{{% /tab %}}
{{% tab "GoFish" %}}

  {{< readFile file="static/snippet/docs/install/gofish.md" markdown="true" >}}

{{% /tab %}}
{{% tab "nix-env" %}}

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html):`

```sh
nix-env -f channel:nixos-unstable -iA fluxcd
```

{{% /tab %}}
{{% /tabs %}}

## Install using curl

1. Download the latest release with the command:

    {{< readFile file="static/snippet/docs/install/curllinux.md" markdown="true" >}}

1. Validate the archive (optional)

    Download the checksum file:

    {{< readFile file="static/snippet/docs/install/downloadchecksum.md" markdown="true" >}}

    Validate the flux archive against the checksum file

    {{< readFile file="static/snippet/docs/install/verifychecksumlinux.md" markdown="true" >}}

    If valid, the output is similar to:

    ```bash
    flux_0.17.0_linux_amd64.tar.gz: OK
    ```

    If the check fails, ``sha256sum`` exits with nonzero status and prints output similar to:

    ```bash
    flux_0.17.0_linux_amd64.tar.gz: no file was verified
    ```

2. Extract the binary

    {{< readFile file="static/snippet/docs/install/extractlinux.md" markdown="true" >}}

3. Install Flux

    ```bash
    sudo install -o root -g root -m 0755 flux /usr/local/bin/flux
    ```

4. Verify installation

    ```bash
    flux --version
    ```

## shell autocomplete

{{< readFile file="static/snippet/docs/install/autocomplete.md" markdown="true" >}}
