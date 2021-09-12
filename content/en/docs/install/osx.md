---
title: "Install the Flux CLI on macOS"
linkTitle: "macOS"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
---

## Install using a package manager

{{% tabs %}}
{{% tab "Homebrew" %}}

  {{< readFile file="static/snippet/docs/install/homebrew.md" markdown="true" >}}

{{% /tab %}}
{{% tab "GoFish" %}}

  {{< readFile file="static/snippet/docs/install/gofish.md" markdown="true" >}}

{{% /tab %}}
{{% /tabs %}}

## Install using curl

1. Download the latest release using ``curl``:

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< codeblock file="static/snippet/docs/install/curldarwin_amd64.sh" language="bash" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< codeblock file="static/snippet/docs/install/curldarwin_arm64.sh" language="bash" >}}

  {{% /tab %}}
  {{% /tabs %}}

2. Validate the archive (optional)

  Download the flux checksum file:

  {{< codeblock file="static/snippet/docs/install/curlchecksum.sh" language="bash" >}}

  Validate the archive against the checksum file:

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< codeblock file="static/snippet/docs/install/verifydarwin_amd64.sh" language="bash" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< codeblock file="static/snippet/docs/install/verifydarwin_arm64.sh" language="bash" >}}

  {{% /tab %}}
  {{% /tabs %}}

  If valid, the output is similar to:

  ```bash
  flux_0.17.0_darwin_amd64.tar.gz: OK
  ```

  If the check fails, ``sha256sum`` exits with nonzero status and prints output similar to:

  ```bash
  flux_0.17.0_darwin_amd64.tar.gz: no file was verified
  ```

3. Extract the archive with ``tar``:

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< codeblock file="static/snippet/docs/install/tardarwin_amd64.sh" language="bash" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< codeblock file="static/snippet/docs/install/tardarwin_arm64.sh" language="bash" >}}

  {{% /tab %}}
  {{% /tabs %}}

4. Move the flux Binary to a file location on your system ``PATH``.

  ```bash
  sudo mv ./flux /usr/local/bin/flux
  sudo chown root: /usr/local/bin/flux
  ```

5. Verify installation

  ```bash
  flux --version
  ```

## Enable shell autocompletion

{{< readFile file="static/snippet/docs/install/autocomplete.md" markdown="true" >}}
