---
title: "Bootstrap Flux on a Generic Git Server"
linkTitle: "Generic Git"
weight: 515
---

## Before you begin

To follow this guide you will need the following:

- The Flux CLI. [Install the Flux CLI](../../installation.md#install-the-flux-cli)
- A Kubernetes Cluster.

## Run bootstrap

You can use either SSH or HTTPS authentication for connecting to Git.

{{% tabs %}}
{{% tab SSH %}}
Run bootstrap for a Git repository and authenticate with your SSH agent:

```bash
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=<my-branch> \
```
{{% /tab %}}
{{% tab HTTPS %}}

```bash
flux bootstrap git \
  --url=https://<host>/<org>/<repository> \
  --username=<my-username> \
  --password=<my-password> \
  --token-auth=true
```

{{% note %}}
If your Git server uses a self-signed TLS certificate, you can specify the CA file with
--ca-file=<path/to/ca.crt>.
{{% /note %}}
{{% /tab %}}
{{% tabs %}}
