---
title: "Flux air-gapped installation"
linkTitle: "Air-Gapped installation"
description: "How to configure Flux for air-gapped clusters"
weight: 15
---

Flux can be installed on air-gapped environments where the Kubernetes cluster,
the container registry and the Git server are not connected to the internet.

## Copy the container images

On a machine with access to `github.com` and `ghcr.io`,
download the Flux CLI from [GitHub releases page](https://github.com/fluxcd/flux2/releases).

List the Flux container images with:

```console
$ flux install --export | grep ghcr.io
image: ghcr.io/fluxcd/source-controller:v1.0.0
image: ghcr.io/fluxcd/kustomize-controller:v1.0.0
image: ghcr.io/fluxcd/helm-controller:v0.35.0
image: ghcr.io/fluxcd/notification-controller:v1.0.0
```

Copy each controller image to your private container registry using
[crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md):

```sh
crane copy ghcr.io/fluxcd/source-controller:v1.0.0 registry.internal/fluxcd/source-controller:v1.0.0
```

## Configure the image pull secret

From a machine inside the air-gapped network
create the pull secret in the `flux-system` namespace:

```sh
kubectl create ns flux-system

kubectl -n flux-system create secret generic regcred \
  --from-file=.dockerconfigjson=/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

## Bootstrap Flux

Copy the Flux CLI binary to the machine inside the air-gapped network and
run bootstrap using the images from your private registry:

```sh
flux bootstrap git \
  --registry=registry.internal/fluxcd \
  --image-pull-secret=regcred \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=<my-branch> \
  --private-key-file=<path/to/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

**Note** that you must generate a SSH private key and set the public key
as the deploy key on your Git server in advance.

For more information on how to use the `flux bootstrap git` command,
please see the generic Git server [documentation](/flux/installation/bootstrap/generic-git-server/).
