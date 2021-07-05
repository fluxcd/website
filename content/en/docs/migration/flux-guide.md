---
title: "Migrate from Flux v1 to v2"
linkTitle: "Migrate from Flux v1"
description: "How to migrate from Flux v1 to v2."
weight: 10
card:
  name: migration
  weight: 10
---

This guide walks you through migrating from Flux v1 to v2.

Read the [FAQ]({{< relref "/faq-migration" >}}) to find out what differences are between v1 and v2.

{{% alert color="info" title="Feature parity" %}}
"Feature parity" does not mean Flux v2 works exactly the same as v1 (or is
backward-compatible); it means you can accomplish the same results, while
accounting for the fact that it's a system with a substantially different
design.
This may at times mean that you have to make adjustments to the way your
current cluster configuration is structured. If you are in this situation
and need help, refer to the [support page](https://fluxcd.io/support/).
{{% /alert %}}

## Prerequisites

- Flux CLI
- Kubernetes cluster version **1.16** or newer
- ``kubectl`` version **1.18** or newer.

## GitOps migration

With this method, you follow the usual bootstrap procedure, which creates a new git repository, then move your manifests over.

Flux v2 offers an installation procedure that is declarative first
and disaster resilient.

Using the `flux bootstrap` command you can install Flux on a Kubernetes cluster and configure it to manage itself from a Git repository. The Git repository created during bootstrap can be used to define the state of your fleet of Kubernetes clusters.

For a detailed walk-through of the bootstrap procedure see the [installation
guide](../installation/_index.md).

{{% alert color="info" color="warning" title="'flux bootstrap' target" %}}
`flux bootstrap` must not be run against a Git branch or path
that is already being synchronized by Flux v1, as this will make
them fight over the resources. Bootstrap to a **new Git
repository, branch or path**, and continue with moving the
manifests.
{{% /alert %}}

After installing Flux v2 on your cluster using bootstrap, you can delete the Flux v1 from your clusters and move the manifests from the Flux v1 repository to the bootstrap one.

## In-place migration

{{% alert color="info" color="warning" %}}
For production use we recommend using the **bootstrap** procedure (see the [Gitops migration](#gitops-migration) section above).
{{% /alert %}}

With this migration method, you use the same repo for your flux V1 installation for flux v2.

This method installs flux v2 in a similar way to how you would install flux v1

### Flux read-only mode

Assuming you've installed Flux v1 to sync a directory with plain YAMLs from a private Git repo:

```sh
# create namespace
kubectl create ns flux

# deploy Flux v1
fluxctl install \
--git-url=git@github.com:org/app \
--git-branch=main \
--git-path=./deploy \
--git-readonly \
--namespace=flux | kubectl apply -f -

# print deploy key
fluxctl identity --k8s-fwd-ns flux

# trigger sync
fluxctl sync --k8s-fwd-ns flux
```

{{% alert color="info" title="Uninstall Flux v1" %}}
Before you proceed, scale the Flux v1 deployment to zero
or delete its namespace and RBAC.
{{% /alert %}}

#### Excluding Source Files

You can exclude YAML files from being applied on the cluster by placing a `.sourceignore` file in your repo root.

```sh
$ cat .sourceignore
# exclude all
/*
# include deploy dir
!/deploy
# exclude files from deploy dir
/deploy/**/eksctl.yaml
/deploy/**/charts
```

#### Install Flux v2 in the `flux-system` namespace

```sh
$ flux install \
  --network-policy=true \
  --watch-all-namespaces=true \
  --namespace=flux-system
✚ generating manifests
✔ manifests build completed
► installing components in flux-system namespace
✔ install completed
◎ verifying installation
✔ source-controller ready
✔ kustomize-controller ready
✔ helm-controller ready
✔ notification-controller ready
✔ install finished
```

#### Register your Git repository and add the deploy key with read-only access

Create a source for the Git Repository you have configured with Flux V1

```sh
flux create source git app \
  --url=ssh://git@github.com/org/app \
  --branch=main \
  --interval=1m
```

While creating the source, a deploy key will be generated.

Add the deploy key as Read Only to your repository, input ``y`` and enter to continue

```bash
► generating deploy key pair
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCp2x9ghVmv1zD...
Have you added the deploy key to your repository: y
...
◎ waiting for GitRepository source reconciliation
✔ GitRepository source reconciliation completed
✔ fetched revision: main/5302d04c2ab8f0579500747efa0fe7abc72c8f9b
```

#### Configure the reconciliation of the `deploy` dir on your cluster

```sh
$ flux create kustomization app \
  --source=GitRepository/app \
  --path="./deploy" \
  --prune=true \
  --interval=10m
✚ generating Kustomization
► applying Kustomization
✔ Kustomization created
◎ waiting for Kustomization reconciliation
✔ Kustomization app is ready
✔ applied revision main/5302d04c2ab8f0579500747efa0fe7abc72c8f9b
```

If your repository contains secrets encrypted with Mozilla SOPS, read this
[guide](../installation/_index.md).

Pull changes from Git and apply them immediately:

```sh
flux reconcile kustomization app --with-source 
```

List all Kubernetes objects reconciled by `app`:

```sh
kubectl get all --all-namespaces \
-l=kustomize.toolkit.fluxcd.io/name=app \
-l=kustomize.toolkit.fluxcd.io/namespace=flux-system
```

### Flux with Kustomize

This guide assumes your Flux v1 installation is configured to sync a Kustomize overlay from an HTTPS Git repository.

```sh
fluxctl install \
--git-url=https://github.com/org/app \
--git-branch=main \
--manifest-generation \
--namespace=flux | kubectl apply -f -
```

With the following `.flux.yaml` in the root dir:

```yaml
version: 1
patchUpdated:
  generators:
    - command: kustomize build ./overlays/prod
  patchFile: flux-patch.yaml
```

{{% alert color="info" title="Uninstall Flux v1" %}}
Before you proceed, delete the Flux v1 namespace
and remove the `.flux.yaml` from your repo.
{{% /alert %}}

Install Flux v2 in the `flux-system` namespace:

```sh
flux install
```

Register the Git repository using a personal access token:

```sh
flux create source git app \
  --url=https://github.com/org/app \
  --branch=main \
  --username=git \
  --password=token \
  --interval=1m
```

Configure the reconciliation of the `prod` overlay on your cluster:

```sh
flux create kustomization app \
  --source=GitRepository/app \
  --path="./overlays/prod" \
  --prune=true \
  --interval=10m
```

Check the status of the Kustomization reconciliation:

```sh
$ flux get kustomizations app
NAME  REVISION                                      SUSPENDED READY
app  main/5302d04c2ab8f0579500747efa0fe7abc72c8f9b False     True
```

### Flux with Slack notifications

Assuming you have configured Flux v1 to send notifications to Slack with
[FluxCloud](https://github.com/justinbarrick/fluxcloud).

Follow the [notifications guide]({{< relref "../guides/notifications.md" >}}) to setup slack notifications for Flux V2

For more details on setting up notifications see
[notifications]({{< relref "../guides/notifications.md" >}}) and
[webhooks]({{< relref "../guides/webhook-receivers.md" >}}).

### Flux debugging

Check the status of Git operations by running the command

```sh
$ kubectl -n flux-system get gitrepositories
NAME READY MESSAGE                                                                                                                                                                                      
app  True  Fetched revision: main/5302d04c2ab8f0579500747efa0fe7abc72c8f9b                                                                                                                                
test False SSH handshake failed: unable to authenticate, attempted methods [none publickey]
```

Check the status of the cluster reconciliation with `kubectl`

```sh
$ kubectl -n flux-system get kustomizations
NAME   READY   STATUS
app    True    Applied revision: main/5302d04c2ab8f0579500747efa0fe7abc72c8f9
test   False   The Service 'backend' is invalid: spec.type: Unsupported value: 'Ingress'
```

Suspend a reconciliation

```sh
$ flux suspend kustomization app
► suspending kustomization app in flux-system namespace
✔ kustomization suspended
```

Check the status with `kubectl`

```sh
$ kubectl -n flux-system get kustomization app
NAME   READY   STATUS
app    False   Kustomization is suspended, skipping reconciliation
```

Resume a reconciliation

```sh
$ flux resume kustomization app
► resuming Kustomization app in flux-system namespace
✔ Kustomization resumed
◎ waiting for Kustomization reconciliation
✔ Kustomization reconciliation completed
✔ applied revision main/5302d04c2ab8f0579500747efa0fe7abc72c8f9b
```
