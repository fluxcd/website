---
title: Using Flux on AWS With CodeCommit
linkTitle: AWS CodeCommit
description: "How to bootstrap Flux on AWS EKS with CodeCommit Git repositories."
weight: 10
---

## EKS Cluster Options

### VPC CodeCommit Access

If your VPC is setup without internet access or you would prefer that the access was over a private connection, you
will need to set up a VPC endpoint to have access to CodeCommit. You can do this by following the guide [Using AWS
CodeCommit with interface VPC endpoints](https://docs.aws.amazon.com/codecommit/latest/userguide/codecommit-and-interface-VPC.html).

### Cluster Creation

The following creates an EKS cluster with some minimal configuration that will work well with Flux:

```sh
eksctl create cluster
```

For more details on how to create an EKS cluster with `eksctl` please see [eksctl.io](https://eksctl.io).

## Flux Installation for AWS CodeCommit

You can install Flux using a AWS CodeCommit repository using the [`flux bootstrap git`](../installation.md#bootstrap)
command.
Ensure you can login to console.aws.amazon.com for your proper organization, and create a new repository to hold your Flux
install and other Kubernetes resources.

To bootstrap using HTTPS, run the following command:
```sh
flux bootstrap git \
  --url=https://git-codecommit.<region>.amazonaws.com/v1/repos/<repository> \
  --branch=main \
  --username=<my-username> \
  --password=<my-password> \
  --token-auth=true
```

To bootstrap using SSH, you first need to generate a SSH keypair to be used as a deploy key.
AWS CodeCommit does not support repository or org-specific SSH/deploy keys. You may add the deploy
key to a user's personal SSH keys, but take note that revoking the user's access to the repository
will also revoke Flux's access. The better alternative is to create a machine-user whose sole
purpose is to store credentials for automation. Using a machine-user also has the benefit of being
able to be read-only or restricted to specific repositories if this is needed.
```sh
aws iam upload-ssh-public-key --user-name codecommit-user --ssh-public-key-body file://sshkey.pub
```

The output shall contain a field `SSHPublicKeyID`, which acts as the SSH username.
```json
{
    "SSHPublicKey": {
        "UserName": "codecommit-user",
        "SSHPublicKeyId": "<SSH-Key-ID>",
        "Fingerprint": "<fingerprint>",
        "SSHPublicKeyBody": "<public-key>",
        "Status": "Active",
        "UploadDate": "2022-11-14T15:15:12+00:00"
    }
}
```

Now we can run the bootstrap command:
```sh
flux bootstrap git \
  --url=ssh://<SSH-Key-ID>@git-codecommit.<region>.amazonaws.com/v1/repos/<repository>
  --branch=main
  --private-key-file=</path/to/private.key>
  --password=<my-ssh-passphrase>
  --silent
```

{{% alert color="info" %}}
Unlike other Git providers, in the case of AWS CodeCommit, you can not use HTTPS for bootstraping
and SSH for driving the reconciliation forward, i.e. you can not provide a HTTPS url without
passing `--token-auth=true` as well.
{{% /alert %}}

{{% alert color="info" %}}
Unlike `git`, Flux does not support the ["shorter" scp-like syntax for the SSH
protocol](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#_the_ssh_protocol)
(e.g. `git-codecommit.<region>.amazonaws.com:v1`).
Use the [RFC 3986 compatible syntax](https://tools.ietf.org/html/rfc3986#section-3) instead: `git-codecommit.<region>.amazonaws.com/v1`.
{{% /alert %}}

## Secrets Management with SOPS and AWS KMS

You will need to use AWS KMS and enable the IAM OIDC provider on the cluster.

Patch kustomize-controller with the proper IAM credentials, so that it may access your AWS KMS, and then begin
committing SOPS encrypted files to the Git repository with the proper AWS KMS configuration.

See the [Mozilla SOPS AWS Guide](../guides/mozilla-sops.md#aws) for further detail.

## Image Updates with Elastic Container Registry

You will need to create an ECR registry and setup an IAM Role with the [required
permissions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html).

{{% alert color="info" %}}
If you used `eksctl` or the AWS CloudFormation templates in [Getting Started with Amazon
EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html) to create your cluster and worker
node groups, these IAM permissions are applied to your worker node IAM Role by default.
{{% /alert %}}

Follow the [Image Update Automation Guide](../guides/image-update.md) and see the
[ECR specific section](../guides/image-update.md#aws-elastic-container-registry) for more details.

Your EKS cluster's configuration can also be updated to
[allow the kubelets to pull images from ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html)
without ImagePullSecrets as an optional, complimentary step.
