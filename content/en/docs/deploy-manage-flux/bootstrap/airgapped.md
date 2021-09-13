---
title: "Bootstrap Flux in an Air-gapped Environment"
linkTitle: "Airgapped Environment"
---

## Before you begin

To follow this guide, you need the following:

- A Kubernetes Cluster
- The Flux CLI installed
  - On the workstation you are using to download images
  - On the workstation you are using to interact with the Cluster
- A private image registry accessible to the cluster

## Pull Flux Images

On a workstation with internet access, pull Flux component images.

1. List all Flux images:

  ```bash
  flux install --export | grep ghcr.io

  image: ghcr.io/fluxcd/helm-controller:v0.8.0
  image: ghcr.io/fluxcd/kustomize-controller:v0.9.0
  image: ghcr.io/fluxcd/notification-controller:v0.9.0
  image: ghcr.io/fluxcd/source-controller:v0.9.0
  ```

2. Pull Flux images to your local machine:

  ```bash
  docker pull ghcr.io/fluxcd/source-controller:v0.9.0
  docker pull ghcr.io/fluxcd/kustomize-controller:v0.9.0
  docker pull ghcr.io/fluxcd/notification-controller:v0.9.0
  docker pull ghcr.io/fluxcd/source-controller:v0.9.0
  ```

## Copy Images to your Air Gapped Workstation

To push the images from another workstation that doesn't have internet access, but is accessible over the network the following steps apply.

On the workstation used to pull the Flux images:

1. Archive the flux images using ``docker save``

  ```bash
  docker save -o \
    ghcr.io/fluxcd/source-controller:v0.9.0 \
    ghcr.io/fluxcd/kustomize-controller:v0.9.0 \
    ghcr.io/fluxcd/notification-controller:v0.9.0 \
    ghcr.io/fluxcd/source-controller:v0.9.0 \
    flux-images.tar
  ```

2. Copy the images to the Air-gapped workstation:

  ```bash
  rsync flux-images.tar user@airgapped-workstation:~/
  ```

On the air gapped workstation:

1. Load the images:

  ```bash
  docker load -i flux-images.tar
  ```

## Tag and Push Flux images to your private registry

Tag and push the images to your private registry:

```
docker tag ghcr.io/fluxcd/source-controller:v0.9.0 registry.internal/fluxcd/source-controller:v0.9.0
docker push registry.internal/fluxcd/source-controller:v0.9.0
...
```

## Create the image pull secret

On the workstation with access to your air-gapped cluster:

1. Create the ``flux-system`` namespace:

  ```bash
  kubectl create ns flux-system
  ```

2. Create the image pull secret for Flux:

  ```bash
  kubectl -n flux-system create secret generic flux-image-cred \
      --from-file=.dockerconfigjson=/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson
  ```

## Bootstrap Flux

On the workstation with access to your air-gapped cluster:

- Bootstrap Flux using the images from your private registry:

  ```bash
  flux bootstrap <GIT-PROVIDER> \
    --registry=registry.internal/fluxcd \
    --image-pull-secret=flux-image-cred \
    --hostname=my-git-server.internal
  ```

{{% note %}}
When running `flux bootstrap` without specifying a `--version`,
the CLI will use the manifests embedded in its binary instead of downloading
them from GitHub. You can determine which version you'll be installing,
with `flux --version`.
{{% /note %}}
