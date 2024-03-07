---
title: "Get Started with Flux"
linkTitle: "Get Started"
description: "Get Started with Flux."
weight: 20
---

This tutorial shows you how to bootstrap Flux to a Kubernetes cluster and deploy a sample application in a GitOps manner.

## Before you begin

To follow the guide, you need the following:

- **A Kubernetes cluster**. We recommend [Kubernetes kind](https://kind.sigs.k8s.io/docs/user/quick-start/) for trying Flux out in a local development environment.
- **A GitHub personal access token with repo permissions**. See the GitHub documentation on [creating a personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

Note that for production use, it is recommended to have a dedicated GitHub account for Flux and 
use [fine-grained access tokens](/flux/installation/bootstrap/github/#github-organization) with the minimum required permissions.

## Objectives

- Bootstrap Flux on a Kubernetes Cluster.
- Deploy a sample application using Flux.
- Customize application configuration through Kustomize patches.

## Install the Flux CLI

The `flux` command-line interface (CLI) is used to bootstrap and interact with Flux.

To install the CLI with Homebrew run:

```sh
brew install fluxcd/tap/flux
```

For other installation methods, see the [CLI install documentation](/flux/installation/#install-the-flux-cli).

## Export your credentials

Export your GitHub personal access token and username:

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
```

## Check your Kubernetes cluster

Check you have everything needed to run Flux by running the following command:

```bash
flux check --pre
```

The output is similar to:

```
► checking prerequisites
✔ kubernetes 1.28.0 >=1.25.0
✔ prerequisites checks passed
```

## Install Flux onto your cluster

For information on how to bootstrap using a GitHub org, Gitlab and other git providers, see [Bootstrapping](/flux/installation/bootstrap/).

Run the bootstrap command:

```sh
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

The output is similar to:

```
► connecting to github.com
✔ repository created
✔ repository cloned
✚ generating manifests
✔ components manifests pushed
► installing components in flux-system namespace
deployment "source-controller" successfully rolled out
deployment "kustomize-controller" successfully rolled out
deployment "helm-controller" successfully rolled out
deployment "notification-controller" successfully rolled out
✔ install completed
► configuring deploy key
✔ deploy key configured
► generating sync manifests
✔ sync manifests pushed
► applying sync manifests
◎ waiting for cluster sync
✔ bootstrap finished
```

The bootstrap command above does the following:

- Creates a git repository `fleet-infra` on your GitHub account.
- Adds Flux component manifests to the repository.
- Deploys Flux Components to your Kubernetes Cluster.
- Configures Flux components to track the path `/clusters/my-cluster/` in the repository.

## Clone the git repository

Clone the `fleet-infra` repository to your local machine:

```sh
git clone https://github.com/$GITHUB_USER/fleet-infra
cd fleet-infra
```

## Add podinfo repository to Flux

This example uses a public repository [github.com/stefanprodan/podinfo](https://github.com/stefanprodan/podinfo),
podinfo is a tiny web application made with Go.

1. Create a [GitRepository](/flux/components/source/gitrepositories/) manifest pointing to podinfo repository's master branch:

    ```sh
    flux create source git podinfo \
      --url=https://github.com/stefanprodan/podinfo \
      --branch=master \
      --interval=1m \
      --export > ./clusters/my-cluster/podinfo-source.yaml
    ```

    The output is similar to:

    ```yaml
    apiVersion: source.toolkit.fluxcd.io/v1
    kind: GitRepository
    metadata:
      name: podinfo
      namespace: flux-system
    spec:
      interval: 1m
      ref:
        branch: master
      url: https://github.com/stefanprodan/podinfo
    ```

2. Commit and push the `podinfo-source.yaml` file to the `fleet-infra` repository:

    ```sh
    git add -A && git commit -m "Add podinfo GitRepository"
    git push
    ```

## Deploy podinfo application

Configure Flux to build and apply the [kustomize](https://github.com/stefanprodan/podinfo/tree/master/kustomize)
directory located in the podinfo repository.

1. Use the `flux create` command to create a [Kustomization](/flux/components/kustomize/kustomizations/) that applies the podinfo deployment.

    ```sh
    flux create kustomization podinfo \
      --target-namespace=default \
      --source=podinfo \
      --path="./kustomize" \
      --prune=true \
      --wait=true \
      --interval=30m \
      --retry-interval=2m \
      --health-check-timeout=3m \
      --export > ./clusters/my-cluster/podinfo-kustomization.yaml
    ```

    The output is similar to:

    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1
    kind: Kustomization
    metadata:
      name: podinfo
      namespace: flux-system
    spec:
      interval: 30m0s
      path: ./kustomize
      prune: true
      retryInterval: 2m0s
      sourceRef:
        kind: GitRepository
        name: podinfo
      targetNamespace: default
      timeout: 3m0s
      wait: true
    ```

2. Commit and push the `Kustomization` manifest to the repository:

    ```sh
    git add -A && git commit -m "Add podinfo Kustomization"
    git push
    ```

    The structure of the `fleet-infra` repo should be similar to:

      ```
      fleet-infra
      └── clusters/
          └── my-cluster/
              ├── flux-system/                        
              │   ├── gotk-components.yaml
              │   ├── gotk-sync.yaml
              │   └── kustomization.yaml
              ├── podinfo-kustomization.yaml
              └── podinfo-source.yaml
      ```

## Watch Flux sync the application

1. Use the `flux get` command to watch the podinfo app.

    ```sh
    flux get kustomizations --watch
    ```

    The output is similar to:

    ```
    NAME          REVISION             SUSPENDED  READY   MESSAGE
    flux-system   main@sha1:4e9c917f   False      True    Applied revision: main@sha1:4e9c917f
    podinfo       master@sha1:44157ecd False      True    Applied revision: master@sha1:44157ecd
    ```

2. Check podinfo has been deployed on your cluster:

    ```sh
    kubectl -n default get deployments,services
    ```

    The output is similar to:

    ```
    NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/podinfo   2/2     2            2           108s

    NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
    service/podinfo      ClusterIP   10.100.149.126   <none>        9898/TCP,9999/TCP   108s
    ```

Changes made to the podinfo
Kubernetes manifests in the master branch are reflected in your cluster.

When a Kubernetes manifest is removed from the podinfo repository, Flux removes it from your cluster.
When you delete a `Kustomization` from the `fleet-infra` repository, Flux removes all Kubernetes objects previously applied from that `Kustomization`.

When you alter the podinfo deployment using `kubectl edit`, the changes are reverted to match
the state described in Git.

## Suspend updates

Suspending updates to a kustomization allows you to directly edit objects applied from a kustomization, without your changes being reverted by the state in Git.

To suspend updates for a kustomization, run the command `flux suspend kustomization <name>`.

To resume updates run the command `flux resume kustomization <name>`.

## Customize podinfo deployment

To customize a deployment from a repository you don't control, you can use Flux
[in-line patches](/flux/components/kustomize/kustomizations/#patches). The following example shows how to use in-line patches to change the podinfo deployment.

1. Add the following to the field `spec` of your `podinfo-kustomization.yaml` file:

    ```yaml clusters/my-cluster/podinfo-kustomization.yaml
      patches:
        - patch: |-
            apiVersion: autoscaling/v2
            kind: HorizontalPodAutoscaler
            metadata:
              name: podinfo
            spec:
              minReplicas: 3     
          target:
            name: podinfo
            kind: HorizontalPodAutoscaler
    ```

1. Commit and push the `podinfo-kustomization.yaml` changes:

    ```sh
    git add -A && git commit -m "Increase podinfo minimum replicas"
    git push
    ```

After the synchronization finishes, running `kubectl get pods` should display 3 pods.

## Multi-cluster Setup

To use Flux to manage more than one cluster or promote deployments from staging to production, take a look at the 
two approaches in the repositories listed below.

1. [https://github.com/fluxcd/flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)
2. [https://github.com/fluxcd/flux2-multi-tenancy](https://github.com/fluxcd/flux2-multi-tenancy)
