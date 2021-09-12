---
title: "Install the Flux CLI on Mac"
linkTitle: "Install the Flux CLI on Mac"
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

1. Download the latest release:

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< readFile file="static/snippet/docs/install/curlosxintel.md" markdown="true" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< readFile file="static/snippet/docs/install/curlosxarm.md" markdown="true" >}}

  {{% /tab %}}
  {{% /tabs %}}

2. Validate the archive (optional)

  Download the flux checksum file:

  {{< readFile file="static/snippet/docs/install/downloadchecksum.md" markdown="true" >}}

  Validate the archive against the checksum file:

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< readFile file="static/snippet/docs/install/verifychecksumosxintel.md" markdown="true" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< readFile file="static/snippet/docs/install/verifychecksumosxarm.md" markdown="true" >}}

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

3. Extract the archive

  {{% tabs %}}
  {{% tab "Intel" %}}

  {{< readFile file="static/snippet/docs/install/extractosxintel.md" markdown="true" >}}

  {{% /tab %}}
  {{% tab "Apple Silicon" %}}

  {{< readFile file="static/snippet/docs/install/extractosxarm.md" markdown="true" >}}

  {{% /tab %}}
  {{% /tabs %}}

4. Move the flux Binary to a file location on your system ``PATH``.

  ```bash
  sudo mv ./flux /usr/local/bin/flux
  sudo chown root: /usr/local/bin/flux
  ```

5. Verify installation

  ```flux --version```

## Enable shell autocompletion

{{< readFile file="static/snippet/docs/install/autocomplete.md" markdown="true" >}}
