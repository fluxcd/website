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

    {{< codeblock file="static/snippet/docs/install/curllinux_amd64.sh" language="bash" >}}

2. Validate the archive (optional)

    Download the checksum file:

    {{< codeblock file="static/snippet/docs/install/curlchecksum.sh" language="bash" >}}

    Validate the flux archive against the checksum file

    {{< codeblock file="static/snippet/docs/install/verifylinux_amd64.sh" language="bash" >}}

    If valid, the output is similar to:

    ```bash
    flux_0.17.0_linux_amd64.tar.gz: OK
    ```

    If the check fails, ``sha256sum`` exits with nonzero status and prints output similar to:

    ```bash
    flux_0.17.0_linux_amd64.tar.gz: no file was verified
    ```

3. Extract the binary

    {{< codeblock file="static/snippet/docs/install/tarlinux_amd64.sh" language="bash" >}}

4. Install Flux

    ```bash
    sudo install -o root -g root -m 0755 flux /usr/local/bin/flux
    ```

5. Verify installation

    ```bash
    flux --version
    ```

## shell autocomplete

{{< readFile file="static/snippet/docs/install/autocomplete.md" markdown="true" >}}
