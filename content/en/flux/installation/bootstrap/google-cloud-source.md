---
title: Flux bootstrap for Google Cloud Source
linkTitle: Google Cloud Source
description: "How to bootstrap Flux with Google Cloud Source Repository"
weight: 70
---

To install Flux on a GKE cluster using a Google Cloud Source repository as the source of truth,
you can use the [`flux bootstrap git`](generic-git-server.md) command.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to have **pull and push rights** for the Google Cloud Source repository.
{{% /alert %}}

## Bootstrap over SSH

First create a new repository to hold your Flux install and other Kubernetes resources.
Then generate a SSH key and add the SSH public key to your personal SSH keys on Google Cloud.

Run bootstrap using the SSH private key and passphrase:

```sh
flux bootstrap git \
  --url=ssh://<user>s@source.developers.google.com:2022/p/<project-name>/r/<repo-name> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

You can also pipe the passphrase e.g. `echo key-passphrase | flux bootstrap git`.

The SSH private key and the known hosts keys are stored in the cluster as a Kubernetes
secret named `flux-system` inside the `flux-system` namespace.

{{% alert color="info" title="SSH Key rotation" %}}
To rotate the SSH public key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a new SSH private key.
{{% /alert %}}
