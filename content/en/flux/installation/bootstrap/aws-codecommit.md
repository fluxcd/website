---
title: Flux bootstrap for AWS CodeCommit
linkTitle: AWS CodeCommit
description: "How to bootstrap Flux with AWS CodeCommit"
weight: 50
---

To install Flux on an EKS cluster using a CodeCommit repository as the source of truth,
you can use the [`flux bootstrap git`](generic-git-server.md) command.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to have **pull and push rights** for the CodeCommit repository.
{{% /alert %}}

## Bootstrap over SSH

{{% alert color="info" title="Private VPC" %}}
If your VPC is configured without internet access, or if you prefer that the access was over a private connection,
you need to set up a VPC endpoint to have access to CodeCommit by following the
guide [Using AWS CodeCommit with interface VPC endpoints](https://docs.aws.amazon.com/codecommit/latest/userguide/codecommit-and-interface-VPC.html).
{{% /alert %}}

Create a new CodeCommit repository and generate a SSH private key with a passphrase.

Upload the SSH public key using the AWS CLI:

```sh
aws iam upload-ssh-public-key --user-name codecommit-user --ssh-public-key-body file://flux.pub
```

The output will contain a field called `SSHPublicKeyID`:

```json
{
    "SSHPublicKey": {
        "SSHPublicKeyId": "<SSH-Key-ID>",
        "Fingerprint": "<fingerprint>",
        "SSHPublicKeyBody": "<public-key>",
        "Status": "Active",
        "UploadDate": "<timestamp>"
    }
}
```

Run bootstrap using the `SSHPublicKeyId` as the SSH username:

```sh
flux bootstrap git \
  --url=ssh://<SSHPublicKeyId>@git-codecommit.<region>.amazonaws.com/v1/repos/<repository> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

You can also pipe the passphrase e.g. `echo key-passphrase | flux bootstrap git`.

The SSH private key and the known hosts keys are stored in the cluster as a Kubernetes
secret named `flux-system` inside the `flux-system` namespace.

{{% alert color="info" title="SSH Key rotation" %}}
To rotate the SSH key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a new SSH private key.
{{% /alert %}}
