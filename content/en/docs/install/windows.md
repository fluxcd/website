---
title: "Install the Flux CLI on Windows"
linkTitle: "Install the Flux CLI Windows"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
---

## Install using a package manager

{{% tabs %}}
{{% tab "Chocolatey" %}}

With [Chocolatey](https://chocolatey.org/):

```powershell
choco install flux
```

{{% /tab %}}
{{% tab "GoFish" %}}

  {{< readFile file="static/snippet/docs/install/gofish.md" markdown="true" >}}

{{% /tab %}}
{{% /tabs %}}

## Install using curl

1. Download the latest release

    {{< codeblock file="static/snippet/docs/install/curlwindows_amd64.ps1" language="powershell" >}}

1. Validate the archive (optional)

    Download the checksum file

    {{< codeblock file="static/snippet/docs/install/curlchecksum.sh" language="powershell" >}}

    Validate the archive against the checksum file

    {{< codeblock file="static/snippet/docs/install/verifywindows_amd64.ps1" language="powershell" >}}
    
    If valid, the output is similar to:

    ```bash
    flux_0.17.0_checksums.txt:4:4f4f9bf34e691d85bad7b0752a0c5471ec665a69d538569daab2b6239a54d83c  flux_0.17.0_windows_amd64.zip
    ```

    If the check fails, no output is displayed.

2. Extract the binary

    {{< codeblock file="static/snippet/docs/install/zipwindows_amd64.ps1" language="powershell" >}}

3. Add the binary in to your ``PATH``.

## Enable shell autocompletion

{{< readFile file="static/snippet/docs/install/autocomplete.md" markdown="true" >}}
