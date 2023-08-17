---
author: developer-guy
date: 2022-10-17 12:30:00+00:00
title: Prove the Authenticity of OCI Artifacts
description: "We'll talk about integration of the cosign tool, which is a tool for signing and verifying the given container images, blobs, etc, that we used to prove the authenticity of the OCI Artifacts we manage through the OCIRepository resources."
url: /blog/2022/10/prove-the-authenticity-of-oci-artifacts
aliases: [/blog/2022/10/prove-the-authenticity-of-the-oci-artifacts]
tags: [oci, security]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

Software supply chain attacks are one of the most critical risks threatening today's software and have begun to collapse like a dark cloud over the software industry. For the Flux family of projects we are taking precautions against these threats. Apart from implementing security features and best practices, it is important to us to educate our users. You can find all Flux's security articles [here](/tags/security/). Today we will talk about a new security feature.

{{< imgproc flux-protects-you-against-ssca-featured Resize x700 >}}
{{< /imgproc >}}

Let's start with a brief historical explanation of how we got to this point. It all started with the following sentence:

{{% pageinfo color="primary" %}}
Flux should be able to distribute and reconcile Kubernetes configuration packaged as OCI artifacts.

> _[RFC-0003: Flux OCI support for Kubernetes manifests](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci)_.
{{% /pageinfo %}}

From then on, the Flux community worked hard and brought this feature with [Flux v0.32](https://github.com/fluxcd/flux2/releases/tag/v0.32.0). So with that, you can store and distribute various sources such as Kubernetes manifests, Kustomize overlays, and Terraform modules as OCI (Open Container Initiative) artifacts with [Flux CLI](/flux/cmd/flux_push_artifact/#flux-push-artifact) and tell Flux to reconcile your sources that are stored in OCI Artifacts, and Flux will do that for you. 🕺🏻

But this only covered the first stage of the entire implementation. There is more than that. ☝️

One of the most exciting features of this RFC is the [verification of artifacts](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci#verify-artifacts). But why, what is it, is it really necessary or just a hype thing? This is a long topic that we need to discuss. Suppose you store the cluster desired state as OCI artifacts in a container registry. How can you be one hundred percent sure that the resources that Flux reconciles are the same as the resources that you've pushed to the OCI registry? This is where the verification of artifacts comes into play. But, how can we do that? 🤔

Thanks to the [Sigstore](https://www.sigstore.dev) community we have a great set of services and tools for signing and verifying authenticity. One of the tools is [cosign](https://docs.sigstore.dev/cosign/overview) which can be used for container signing, verification, and storage in an OCI registry. We will use it to verify the authenticity of the OCI Artifacts in Flux. Starting with [v0.35](https://github.com/fluxcd/flux2/releases/tag/v0.35.0), Flux comes with support for verifying OCI artifacts signed with Sigstore Cosign. Documentation for setting it up can be found [here](/flux/cheatsheets/oci-artifacts/#signing-and-verification).

Let's jump right into the details of how we can actually use it.

We will deploy [cert-manager](https://cert-manager.io/docs/) by storing its manifests in OCI registry packaged as an OCI Artifacts, using the _Flux CLI_. Then we are going to sign it with _cosign_ and configure Flux to verify the artifacts’ signatures before they are downloaded and reconciled.

You need three things to complete this demo;

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

Let's install Flux on it - if you need to use other options, check out the [installation page](/flux/installation/).

```shell
export GITHUB_USER=developer-guy
export GITHUB_TOKEN=$GITHUB_TOKEN

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=flux-cosign-demo \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

> ⚠️ Note: Don’t forget to change the values with your own details!

First we download the cert-manager install manifests from GitHub:

```shell
curl -sSLO https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
```

> <https://github.com/cert-manager/cert-manager/releases/tag/v1.9.1>

Next we push the manifests to GitHub container registry with _Flux CLI_:

```shell
mkdir -p ./manifests
 cp cert-manager.yaml ./manifests
$ flux push artifact oci://ghcr.io/$GITHUB_USER/manifests/cert-manager:v1.9.1 \
  --path="./manifests" \
  --source="https://github.com/cert-manager/cert-manager.git" \
  --revision="v1.9.1/4486c01f726f17d2790a8a563ae6bc6e98465505"
► pushing artifact to ghcr.io/developer-guy/manifests/cert-manager:v1.9.1
✔ artifact successfully pushed to ghcr.io/developer-guy/manifests/cert-manager@sha256:d1fb0442865148a4e9b4c3431c71d8e44af56c3eb658ea495c5ec48d48c6638b
```

Before signing the OCI artifact with Cosign, we need to create a set of key pairs, a public and private one:

```shell
cosign generate-key-pair
```

> This command above outputs two files to disk: `cosign.pub` and `cosign.key`. The cosign.pub file is the public key and the cosign.key file is the private key. You can use the cosign.pub file to verify the container image and the cosign.key file to sign the container image.

To let Flux to verify the signature of the OCI artifact, we should create a secret that contains the public key::

```shell
kubectl -n flux-system create secret generic cosign-pub \
  --from-file=cosign.pub=cosign.pub
```

Now, let's sign it:

```shell
$ cosign sign --key cosign.key ghcr.io/$GITHUB_USER/manifests/cert-manager:v1.9.1
Enter password for private key:
Pushing signature to: ghcr.io/developer-guy/manifests/cert-manager
```

As we stick into the GitOps practices, we should create a file that contains the _OCIRepository_ resource, then commit and push those changes into the upstream repository that Flux watches for changes:

```shell
git clone git@github.com:developer-guy/flux-cosign-demo.git
cd flux-cosign-demo
```

Let's create a secret with the GitHub token:

```shell
$ flux create secret oci ghcr-auth \
  --url=ghcr.io \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN}
► oci secret 'ghcr-auth' created in 'flux-system' namespace
```

Configure Flux to pull the cert-manager artifact, verify its signature and apply its contents:

```shell
cat << EOF | tee ./clusters/my-cluster/cert-manager-sync.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/${GITHUB_USER}/manifests/cert-manager
  ref:
    semver: "*"
  secretRef:
    name: ghcr-auth
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 1h
  timeout: 5m
  sourceRef:
    kind: OCIRepository
    name: cert-manager
  path: "."
  prune: true
  wait: true
EOF
```

Let's commit and push these changes:

```shell
git add .
git commit -m"Add cert-manager OCIRepository and Kustomization"
git push
```

After couple of seconds for Flux will have applied these changes. Now let's check the status of them:
> Or, you can trigger the reconcilation immediately by running the simple command: _flux reconcile source git flux-system_

For _Kustomization_ resources:

```shell
$ flux get kustomizations
NAME            REVISION                                                                SUSPENDED       READY   MESSAGE                                        
cert-manager    v1.9.1/d1fb0442865148a4e9b4c3431c71d8e44af56c3eb658ea495c5ec48d48c6638b False           True    Applied revision: v1.9.1/d1fb0442865148a4e9b4c3431c71d8e44af56c3eb658ea495c5ec48d48c6638b
flux-system     main/14f1e66                                                            False           True    Applied revision: main/14f1e66 
```

For _OCIRepository_ resources:

```shell
$ flux get sources oci
NAME            REVISION                                                                SUSPENDED       READY   MESSAGE                                        
cert-manager    v1.9.1/d1fb0442865148a4e9b4c3431c71d8e44af56c3eb658ea495c5ec48d48c6638b False           True    stored artifact for digest 'v1.9.1/d1fb0442865148a4e9b4c3431c71d8e44af56c3eb658ea495c5ec48d48c6638b'
```

If you see the status of the _OCIRepository_ is `True`, it means that Flux has successfully verified the signature of the container image. Because Flux adds a condition with the following attributes to the OCIRepository’s `.status.conditions`:

* type: SourceVerified
* status: "True"
* reason: Succeeded

If the verification fails, Flux will set the `SourceVerified` status to `False` and will not fetch the artifact contents from the registry. If you see the status of the _Kustomization_ is `True`, it means that Flux has successfully applied the manifests that are stored in the container image.

Let's check the status of the _cert-manager_ deployment:

```shell
$ kubectl get pods --namespace cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-cainjector-857ff8f7cb-l469h   1/1     Running   0          76s
cert-manager-d58554549-9fbgj               1/1     Running   0          76s
cert-manager-webhook-76fdf7c485-9v82g      1/1     Running   0          76s
```

## Furthermore

As we can store _Helm Charts_ in OCI registries with the release of Helm [v3.8.0](https://helm.sh/blog/storing-charts-in-oci/) which means that we can also sign them with _cosign_ and verify them with Flux. The Flux community is already working on it and want to add support for verifying the Helm charts stored in OCI registries as OCI Artifacts in the next releases of Flux. You can follow the progress of this feature in the following issue: [fluxcd/source-controller#914](https://github.com/fluxcd/source-controller/issues/914).

The Sigstore community is aware of the risks and the toil of managing public/private key pairs, so cosign offers another mode for signing and verification called [Keyless](https://github.com/sigstore/cosign/blob/main/KEYLESS.md), which do not require managing any keys manually. Flux also supports that. If you omit the `.verify.secretRef` field, Flux will try to verify the signature using the Keyless mode. It's worth mentioning keyless verification is an experimental feature, using custom root CAs or self-hosted Rekor instances are currently not supported.
