---
author: developer-guy
date: 2022-10-04 11:30:00+00:00
title: Prove the Authenticity of the OCI Artifacts
description: "We'll talk about integration of the cosign tool, which is a tool for signing and verifying the given container images, blobs, etc, that we used to prove the authenticity of the OCI Artifacts we manage through the OCIRepository resources."
url: /blog/2022/10/prove-the-authenticity-of-the-oci-artifacts
tags: [oci]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

Software supply chain attacks are one of the most critical risks threatening today's software, and software has begun to collapse like a dark cloud over the industry. The Flux community is one of those communities that always takes precautions against these threats. While they primarily provided the measures I mentioned for their products, they also provided articles that raised users' awareness of what they were doing to protect against these threats. You can find all Flux's security articles [here](https://fluxcd.io/tags/security/). I strongly recommend you to read these articles. And they did not stop here, they also introduced features in their products that can protect users against these threats, and today we will talk about one of these features.

{{< imgproc flux-protects-you-against-ssca Resize 800x >}}
{{< /imgproc >}}

Let's start with a brief historical explanation of how we got to this point. It all started with the following sentence:

<div style="text-align: center;">
Flux should be able to distribute and reconcile Kubernetes configuration packaged as OCI artifacts.
</div>

> _[RFC-0003: Flux OCI support for Kubernetes manifests](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci)_.

From then on, the Flux community worked hard and brought this feature with [Flux v0.32](https://github.com/fluxcd/flux2/releases/tag/v0.32.0). So with that, you can store and distribute various sources such as Kubernetes manifests, Kustomize overlays, and Terraform modules as OCI (Open Container Initiative) artifacts with [Flux CLI](https://fluxcd.io/flux/cmd/flux_push_artifact/#flux-push-artifact) and tell Flux to reconcile your sources that are stored in OCI Artifacts, and Flux will do that for you. 🕺🏻

But this only covered the first stage of the entire implementation. There is more than that. ☝️

One of the most exciting features of this RCF is the [verification of artifacts](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci#verify-artifacts). But why, what is it, is it really necessary or just a hype thing? This is a long topic that we need to discuss, though, but in its simplest form, suppose you keep your sources that you want Flux to reconcile as an OCI Work, and you push them into one of your favorite OCI logbooks and tell Flux to reconcile them, and Flux does it. But how can you be one hundred percent sure that the resources that Flux reconciles are the same as the resources that you send to the OCI registry? This is where the verification of artifacts comes into play. But, how can we do that and that's another question? 🤔

Thanks to the [Sigstore](https://www.sigstore.dev) community, they provide a set of services and tools that can make that signing and verification process easier for everyone. One of the tools that they provide is [cosign](https://docs.sigstore.dev/cosign/overview) which is a tool for container signing, verification, and storage in an OCI registry and this is the tool we will benefit from to help people to verify the authenticity of the OCI Artifacts in Flux and I'm super excited to announce that starting with [v0.35](https://github.com/fluxcd/flux2/releases/tag/v0.35.0), Flux comes with support for verifying OCI artifacts signed with Sigstore Cosign. Of course, this features takes its place it the official documentation of Flux, you can reach out to it from [here](https://fluxcd.io/flux/cheatsheets/oci-artifacts/#signing-and-verification).

The talk is enough ! Let's jump right into the details of how we can actually use it.

Today, we'll be deploying [Kyverno](https://kyverno.io) project by storing its manifests in OCI registry packaged as an OCI Artifacts, thanks to _Flux CLI_, then we are going to sign it with _cosign_ tool and configure Flux to verify the artifacts’ signatures before they are downloaded and reconciled.

We should have three things to complete this demo;

* _cosign_ CLI
  * <https://docs.sigstore.dev/cosign/installation/>
* A Kubernetes cluster
  * <https://kind.sigs.k8s.io/#installation-and-usage>
* _Flux_ CLI
  * <https://fluxcd.io/flux/cmd/>

Let's start by creating a simple Kubernetes cluster:

```shell
kind create cluster
```

Let's install Flux on it, and I'll not go into the details of the installation process, you might use the [installation page](https://fluxcd.io/flux/installation/) of Flux to get more details about it.

```shell
export GITHUB_USER=developer-guy
export GITHUB_TOKEN=$GITHUB_TOKEN

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=flux-gotk \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

> ⚠️ Note: Don’t forget to change the values with your own details!

Make sure that Flux is up and running:

```shell
$ flux check
► checking prerequisites
✔ Kubernetes 1.25.2 >=1.20.6-0
► checking controllers
✔ helm-controller: deployment ready
► ghcr.io/fluxcd/helm-controller:v0.25.0
✔ kustomize-controller: deployment ready
► ghcr.io/fluxcd/kustomize-controller:v0.29.0
✔ notification-controller: deployment ready
► ghcr.io/fluxcd/notification-controller:v0.27.0
✔ source-controller: deployment ready
► ghcr.io/fluxcd/source-controller:v0.30.0
► checking crds
✔ alerts.notification.toolkit.fluxcd.io/v1beta1
✔ buckets.source.toolkit.fluxcd.io/v1beta2
✔ gitrepositories.source.toolkit.fluxcd.io/v1beta2
✔ helmcharts.source.toolkit.fluxcd.io/v1beta2
✔ helmreleases.helm.toolkit.fluxcd.io/v2beta1
✔ helmrepositories.source.toolkit.fluxcd.io/v1beta2
✔ kustomizations.kustomize.toolkit.fluxcd.io/v1beta2
✔ ocirepositories.source.toolkit.fluxcd.io/v1beta2
✔ providers.notification.toolkit.fluxcd.io/v1beta1
✔ receivers.notification.toolkit.fluxcd.io/v1beta1
✔ all checks passed
```

To be able to push Kyverno manifets into OCI registry, we should clone the Kyverno project first becaut it stores its manifests in a a file called [./config/install.yaml](https://github.com/kyverno/kyverno/blob/main/config/install.yaml):

```shell  
git clone --depth=0 https://github.com/kyverno/kyverno.git
cd kyverno
```

Let's push the manifest into OCI registry with _Flux CLI_:

```shell
mkdir -p ./manifests
cp ./config/install.yaml ./manifests
$ flux push artifact oci://ttl.sh/$GITHUB_USER/manifests/kyverno:$(git tag --points-at HEAD) \
	--path="./manifests" \
	--source="$(git config --get remote.origin.url)" \
	--revision="$(git tag --points-at HEAD)/$(git rev-parse HEAD)"
► pushing artifact to ttl.sh/developer-guy/manifests/kyverno:
✔ artifact successfully pushed to ttl.sh/developer-guy/manifests/kyverno@sha256:478f1a6cff929c6dc8ff18aa134ae5cec232db77286ec65eb745499bffe92975
```

Before actually signing the container image, we should create a set of key pairs, a public and private one:

```shell
cosign generate-key-pair
```

> This command above outputs two files to disk: `cosign.pub` and `cosign.key`. The cosign.pub file is the public key and the cosign.key file is the private key. You can use the cosign.pub file to verify the container image and the cosign.key file to sign the container image.

To let Flux to verify the signature of the container image, we should create a secret that contains the public key:

```shell
kubectl -n flux-system create secret generic cosign-pub \
  --from-file=cosign.pub=cosign.pub
```

Now, let's sign it:

```shell
$ cosign sign --key cosign.key ttl.sh/developer-guy/manifests/kyverno:latest
Enter password for private key:
Pushing signature to: ttl.sh/developer-guy/manifests/kyverno
```

As we stick into the GitOps practices, we should create a file that contains the _OCIRepository_ resource, then commit and push those changes into the upstream repository that Flux watches for changes:

```shell
git clone git@github.com:developer-guy/flux-gotk.git
cd flux-gotk
```

Let's create these two files, one is for _OCIRepository_ that is pointing to our OCI Artifact, the other is for _Kustomization_ that is pointing to the _OCIRepository_:

```shell
cat << EOF | tee ./clusters/my-cluster/kyverno-ocirepository.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: kyverno
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ttl.sh/$GITHUB_USER/manifests/kyverno
  ref:
    tag: "latest"
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
EOF

cat << EOF | tee ./clusters/my-cluster/kyverno-kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: kyverno
  namespace: flux-system
spec:
  interval: 10m
  targetNamespace: kyverno
  sourceRef:
    kind: OCIRepository
    name: kyverno
  path: "."
  prune: true
EOF
```

Let's commit and push these changes:

```shell
git add .
git commit -m"Add kyverno OCIRepository and Kustomization"
git push
```

then, just wait couple of seconds for Flux to apply these changes, then let's check the status of them:

For _Kustomization_ resources:

```shell
$ flux get kustomizations
NAME        REVISION                                                                SUSPENDED READY  MESSAGE
flux-system main/74b7215                                                            False     True   Applied revision: main/74b7215
kyverno     latest/478f1a6cff929c6dc8ff18aa134ae5cec232db77286ec65eb745499bffe92975 False     True   Applied revision: latest/478f1a6cff929c6dc8ff18aa134ae5cec232db77286ec65eb745499bffe92975
```

For _OCIRepository_ resources:

```shell
$ flux get sources oci
NAME    REVISION                                                                SUSPENDED READY MESSAGE
kyverno latest/478f1a6cff929c6dc8ff18aa134ae5cec232db77286ec65eb745499bffe92975 False     True  stored artifact for digest 'latest/478f1a6cff929c6dc8ff18aa134ae5cec232db77286ec65eb745499bffe92975'
```

If you see the status of the _OCIRepository_ is `True`, it means that Flux has successfully verified the signature of the container image. Because Flux adds a condition with the following attributes to the OCIRepository’s `.status.conditions`:

* type: SourceVerified
* status: "True"
* reason: Succeeded

If the verification fails, Flux will set the `SourceVerified` status to `False` and will not fetch the artifact contents from the registry. If you see the status of the _Kustomization_ is `True`, it means that Flux has successfully applied the manifests that are stored in the container image.

Lets check the status of the Kyverno deployment:

```shell
$ kubectl get pods --namespace kyverno
NAME                      READY   STATUS    RESTARTS   AGE
kyverno-7dcf5895c-chgrp   1/1     Running   0          28m
```
