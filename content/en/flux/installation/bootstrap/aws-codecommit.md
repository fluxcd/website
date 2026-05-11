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
It is also required that the person running the command has **pull and push rights** for the CodeCommit repository.
{{% /alert %}}

## Bootstrap over SSH

{{% alert color="info" title="Private VPC" %}}
If your VPC is configured without internet access, or if you prefer that the access is over a private connection,
you need to set up a VPC endpoint to access CodeCommit by following the
guide [Using AWS CodeCommit with interface VPC endpoints](https://docs.aws.amazon.com/codecommit/latest/userguide/codecommit-and-interface-VPC.html).
{{% /alert %}}

Create a CodeCommit repository and generate a PEM-encoded RSA SSH private key
with a passphrase:

```sh
ssh-keygen -t rsa -b 4096 -m PEM -f ./codecommit_rsa
```

Upload the SSH public key to the IAM user that Flux will use to access
CodeCommit:

```sh
aws iam upload-ssh-public-key \
  --user-name codecommit-user \
  --ssh-public-key-body file://codecommit_rsa.pub
```

The output will contain a field called `SSHPublicKeyId`:

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
  --private-key-file=./codecommit_rsa \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

Do not use the IAM user name as the SSH username in the repository URL.
CodeCommit expects the SSH key ID assigned to the uploaded public key.

You can also pipe the passphrase e.g. `echo key-passphrase | flux bootstrap git`.

The SSH private key and the known hosts keys are stored in the cluster as a Kubernetes
secret named `flux-system` inside the `flux-system` namespace.

For the full CodeCommit SSH setup, including where to find the SSH Key ID, see
the AWS CodeCommit SSH documentation for
[Linux, macOS, or Unix](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html)
and [Windows](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-windows.html).

{{% alert color="info" title="SSH Key rotation" %}}
To rotate the SSH key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a new PEM-encoded RSA SSH private key.
{{% /alert %}}
