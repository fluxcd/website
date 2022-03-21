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

The following replicates the [Flux bootstrap procedure](../installation/_index.md#bootstrap) and represents
the best practice for structuring the repository. For more information on the structure of the repository
please see [Ways of structuring your repositories](../installation/repository-structure.md).

Ensure you can login to [console.aws.amazon.com](https://console.aws.amazon.com) for your proper organization,
and create a new repository to hold your Flux install and other Kubernetes resources.

Clone the Git repository locally:

```sh
git clone ssh://Your-SSH-Key-ID@git-codecommit.<region>.amazonaws.com/v1/repos/<my-repository>
cd my-repository
```

Create a directory inside the repository:

```sh
mkdir -p ./clusters/my-cluster/flux-system
```

Download the [Flux CLI](../installation/_index.md#install-the-flux-cli) and generate the manifests with:

```sh
flux install \
  --export > ./clusters/my-cluster/flux-system/gotk-components.yaml
```

Commit and push the manifest to the master branch:

```sh
git add -A && git commit -m "add components" && git push
```

Apply the manifests on your cluster:

```sh
kubectl apply -f ./clusters/my-cluster/flux-system/gotk-components.yaml
```

Verify that the controllers have started:

```sh
flux check
```

Create a `GitRepository` object on your cluster by specifying the SSH address of your repo:

```sh
flux create source git flux-system \
  --git-implementation=libgit2 \
  --url=ssh://Your-SSH-Key-ID@git-codecommit.<region>.amazonaws.com/v1/repos/<my-repository> \
  --branch=<branch> \
  --ssh-key-algorithm=rsa \
  --ssh-rsa-bits=4096 \
  --interval=1m
```

The above command will prompt you to add a deploy key to your repository, but AWS CodeCommit
does not support repository or org-specific deploy keys. You may add the deploy key to a user's
personal SSH keys, but take note that revoking the user's access to the repository will
also revoke Flux's access. The better alternative is to create a machine-user whose sole purpose is
to store credentials for automation. Using a machine-user also has the benefit of being able to be read-only or
restricted to specific repositories if this is needed.

{{% alert color="info" %}}
Unlike `git`, Flux does not support the ["shorter" scp-like syntax for the SSH
protocol](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#_the_ssh_protocol)
(e.g. `git-codecommit.<region>.amazonaws.com:v1`).
Use the [RFC 3986 compatible syntax](https://tools.ietf.org/html/rfc3986#section-3) instead: `git-codecommit.<region>.amazonaws.com/v1`.
{{% /alert %}}

If you wish to use Git over HTTPS, then generate [git credentials for HTTPS connections
to CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html#setting-up-gc-iam)
and use these details as the username and password:

```sh
flux create source git flux-system \
  --git-implementation=libgit2 \
  --url=https://git-codecommit.<region>.amazonaws.com/v1/repos/<my-repository> \
  --branch=main \
  --username=${AWS_IAM_GC_USER} \
  --password=${AWS_IAM_GC_PASS} \
  --interval=1m
```

Create a `Kustomization` object on your cluster:

```sh
flux create kustomization flux-system \
  --source=flux-system \
  --path="./clusters/my-cluster" \
  --prune=true \
  --interval=10m
```

Export both objects, generate a `kustomization.yaml`, commit and push the manifests to Git:

```sh
flux export source git flux-system \
  > ./clusters/my-cluster/flux-system/gotk-sync.yaml

flux export kustomization flux-system \
  >> ./clusters/my-cluster/flux-system/gotk-sync.yaml

cd ./clusters/my-cluster/flux-system && kustomize create --autodetect

git add -A && git commit -m "add sync manifests" && git push
```

Wait for Flux to reconcile your previous commit with:

```sh
flux get kustomizations --watch
```

### Flux Upgrade

To upgrade the Flux components to a newer version, download the latest `flux` binary,
run the install command in your repository root, commit and push the changes:

```sh
flux install \
  --export > ./clusters/my-cluster/flux-system/gotk-components.yaml

git add -A && git commit -m "Upgrade to $(flux -v)" && git push
```

The [source-controller](../components/source/_index.md) will pull the changes on the cluster,
then [kustomize-controller](../components/source/_index.md) will perform a rolling update of
all Flux components including itself.

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
