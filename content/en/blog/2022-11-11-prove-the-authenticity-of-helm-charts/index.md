---
author: developer-guy
date: 2022-11-14 10:30:00+00:00
title: Verify the integrity of the Helm Charts stored in OCI-compliant registries as OCI artifacts
description: "We'll talk about one of the newest support in Flux v0.36 that enables you to prove the authenticity of the Helm charts we manage through the HelmChart resources with the help of the cosign integration."
url: /blog/2022/11/verify-the-integrity-of-the-helm-charts-stored-as-oci-artifacts-before-reconciling-them-with-flux
tags: [oci, security]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

Cosign integration was one of the most important features we shipped in the Flux [v0.35 release](https://github.com/fluxcd/flux2/releases/tag/v0.35.0). After that, we wrote a [blog post](/blog/2022/10/prove-the-authenticity-of-oci-artifacts/) which explains how to use the feature with [OCIRepository](/flux/components/source/ocirepositories/) resources which enables fetching OCI artifacts from container registries. If you haven't read it yet, we highly encourage you to go and check it out first.

{{< imgproc verify-the-integrity-of-the-helm-charts-stored-as-oci-artifacts-before-reconciling-them-with-flux-featured Resize x700 >}}
{{< /imgproc >}}

Flux v0.36.0 allows you to prove the authenticity of [HelmChart](/flux/components/source/helmcharts/) resources with the help of the `cosign` integration.  Here we will demonstrate how to use the cosign integration to verify the integrity of the Helm charts stored in OCI-compliant registries as OCI artifacts.

{{< tweet user="stefanprodan" id="1585710554018037761" >}}

Starting with Helm [v3.8.0](https://helm.sh/blog/storing-charts-in-oci/), Helm supports the OCI registry as a one of the storage option for Helm charts as an alternative to Helm repositories. The [Helm CLI](https://helm.sh/docs/helm/helm/) can push and pull Helm charts to and from OCI-compliant registries.

{{% note %}}
Prior to Helm v3.8.0, OCI support was experimental. To use it there, you need to enable the feature by setting the `HELM_EXPERIMENTAL_OCI` environment variable to `1`.
{{% /note %}}

As we store Helm charts in OCI-compliant registries as OCI artifacts, we can now use the cosign integration to sign and verify them. Also, thanks to Flux, you can reconcile resources such as plain-text Kubernetes YAML manifests, Terraform modules, etc. from OCI-compliant registries with the help of `OCIRepository` resources. You can achieve the same thing for Helm charts with [HelmRepository](/flux/components/source/helmrepositories/#helm-oci-repository) resources. This means that you can store Helm charts in OCI-compliant registries as OCI artifacts and use Flux to reconcile them like the following:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
spec:
  type: "oci"
  interval: 5m0s
  url: oci://ghcr.io/stefanprodan/charts
```

{{% note %}}
Here you can review the complete registries lists that support the OCI artifact specification: [OCI-Conformant Products](https://conformance.opencontainers.org/#distribution-spec).

You will notice that when you open the list, DockerHub is not included into the list but it will be added soon because they recently announced OCI Artifacts support, and you can read more about it from [here](https://www.docker.com/blog/announcing-docker-hub-oci-artifacts-support/).
{{% /note %}}

Let's jump right into the details of how we can actually use it.

We will deploy [Prometheus](https://prometheus.io/) by using its community [Helm charts](https://github.com/prometheus-community/helm-charts) stored as OCI artifacts in OCI registry. Recently, Prometheus' community started to publish their Helm charts to OCI registries and sign them with cosign using the [keyless](https://github.com/sigstore/cosign/blob/main/KEYLESS.md) approach, you can learn more the process [here](https://github.com/prometheus-community/helm-charts/pull/2631). Then we are going to verify it with _cosign_ and configure Flux to verify the Helm chart's signatures before they are downloaded and reconciled. As the Prometheus community signed their Helm Charts without providing a key pair, we do not need to specify any key in the HelmChart resource' `provider.cosign` spec to enable keyless verification for Flux.

> For the sake of simplicity, we've deployed Prometheus alone but if you want to learn more about installing the Prometheus stack including Grafana, Alertmanager, etc., please refer to the official Flux [page](/flux/guides/monitoring) that can help you to do that.

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

Use the Flux CLI to do pre-flight checks:

```shell
$ flux check --pre
► checking prerequisites
✔ Kubernetes 1.25.3 >=1.20.6-0
✔ prerequisites checks passed
```

If the checks are successful, you can install Flux on the cluster.

Let's install Flux on it - if you need to use other options, check out the [installation page](/flux/installation/).

```shell
export GITHUB_USER=developer-guy
export GITHUB_TOKEN=$GITHUB_TOKEN

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=flux-cosign-helm-oci-demo \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

{{% note %}}
Don’t forget to change the values with your own details!
{{% /note %}}

As we stick to GitOps practices, we only create files that contain the `HelmRepository` and `HelmRelease` resources. After committing and pushing those changes into the upstream repository, Flux will watch for changes and use them as source-of-truth for the configuration:

```shell
git clone git@github.com:developer-guy/flux-cosign-helm-oci-demo.git
cd flux-cosign-helm-oci-demo
```

Let's create the _HelmRepository_ resource first:

```shell
flux create source helm prometheus-community \
    --url=oci://ghcr.io/prometheus-community/charts \
    --interval=10m \
    --export > ./clusters/my-cluster/prometheus-community-helmrepository.yaml
```

Now, let's move on with creating the _HelmRelease_ resource:

```shell
flux create helmrelease prometheus \
    --source=HelmRepository/prometheus-community \
    --chart=prometheus \
    --interval=10m \
    --release-name prometheus \
    --target-namespace=monitoring \
    --create-target-namespace \
    --export > ./clusters/my-cluster/prometheus-helmrelease.yaml
```

and run the following command to add the `verify` section to the _HelmRelease_ resource' `.spec.chart.spec` section  to enable keylesss verification:

```shell
yq e '.spec.chart.spec|=({"verify": { "provider": "cosign" } } +.)' ./clusters/my-cluster/prometheus-helmrelease.yaml
```

This command above will add the following part to the `HelmRelease` resource's `.spec.chart.spec` section:

```yaml
verify:
  provider: cosign
```

then, commit and push the changes:

```shell
git commit -m "Add prometheus HelmRelease and HelmRepository resources"
git push
```

After a couple of seconds, Flux will have applied these changes. Now let's check the status of them:

> Or, you can trigger the reconciliation immediately by running the simple command: `flux reconcile source git flux-system`

For the _HelmRepository_ resource:

```shell
$ flux get sources helm
NAME                    REVISION        SUSPENDED       READY   MESSAGE
prometheus-community                    False           True    Helm repository is ready
```

For the _HelmRelease_ resource:

```shell
$ flux get helmreleases
NAME            REVISION        SUSPENDED       READY   MESSAGE
prometheus      15.18.0         False           True    Release reconciliation succeeded
```

If everything is fine, you can check the pods in the `monitoring` namespace:

```shell
$ kubectl get pods -n monitoring
NAME                                             READY   STATUS    RESTARTS   AGE
prometheus-alertmanager-54b7d7cf45-2b7zf         2/2     Running   0          115s
prometheus-kube-state-metrics-67f68d64bb-vlmvd   1/1     Running   0          115s
prometheus-node-exporter-46gm6                   1/1     Running   0          115s
prometheus-pushgateway-596cd99697-t79zt          1/1     Running   0          115s
prometheus-server-c458cf6f9-nvstw                2/2     Running   0          115s
```

Great! Now, you have installed Prometheus with Flux by using the Helm chart stored in the OCI registry and verified it with _cosign_.

We can assume that the Helm chart's signature is verified as we let it be deployed in a cluster but let's do have double check and check the status of the _HelmRelease_ to see whether the verification is successful or not:

```shell
$ kubectl get helmcharts -n flux-system flux-system-prometheus -ojsonpath='{.status.conditions[?(@.type=="SourceVerified")]}'
{"lastTransitionTime":"2022-11-09T13:27:38Z","message":"verified signature of version 15.18.0","observedGeneration":1,"reason":"Succeeded","status":"True","type":"SourceVerified"}
```

That's super cool! Because Flux is going to add a condition to the HelmChart resource's status section to show the verification status. If the verification is successful, it will add a condition like the one above.

## DIY (Do it yourself) Approach

The Prometheus community Helm charts only serve as an example. Here is how you can do the same thing with your own Helm charts.

1. Create a Helm chart
2. Package the Helm chart as .tar.gz file
3. Login to the OCI-compliant registry that you want to use to store your Helm chart
4. Push the Helm chart as OCI artifact

Let's create a sample directory that will contain our Helm chart:

```shell
mkdir -p helm-oci-demo
cd helm-oci demo
```

Now package the Helm chart as .tar.gz file:

```shell
 helm create nginx
```

Let's package the Helm chart as .tar.gz file:

```shell
helm package nginx
```

Now, let's login to the OCI-compliant registry that you want to use to store your Helm chart. In this example, we'll be using the GitHub Container Registry (ghcr.io):

```shell
echo $GHCR_PAT | helm registry login ghcr.io -u $USER --password-stdin
```

{{% note %}}
Don’t forget to change the values with your own details!
{{% /note %}}

At this point, we are ready to push the Helm chart as OCI artifact:

```shell
$ helm push nginx-0.1.0.tgz oci://ghcr.io/$USER
Pushed: ghcr.io/developer-guy/nginx:0.1.0
Digest: sha256:21f92cbd63ab495d8fc44d54dabc4815c88d37697b3f8b757ca8e51ef178a2e7
```

So, the Helm chart is pushed to the OCI registry. It's time to sign it with _cosign_. As [cosign recommends](https://github.com/sigstore/cosign#sign-a-container-and-store-the-signature-in-the-registry) we should always sign images based on their digests (@sha256:) rather than a tag. So, we should grab the digest from the command output above which is `21f92cbd63ab495d8fc44d54dabc4815c88d37697b3f8b757ca8e51ef178a2e7` in this case, and use that digest while signing the image:

As we saw the keyless approach before, let's try the key-based approach this time. To do that, we should create public/private key pairs first:

```shell
cosign generate-key-pair
```

This command will generate two files, a `cosign.pub` which is a publickey and `cosign.key` which is a private key pair and store them in the current directory directory.

Now, let's sign the image with the private key:

```shell
cosign sign --key cosign.key ghcr.io/$USER/nginx@21f92cbd63ab495d8fc44d54dabc4815c88d37697b3f8b757ca8e51ef178a2e7
```

Cool! Now we have signed the image with the private key. Let's check the signature:

```shell
cosign verify --key cosign.key ghcr.io/$USER/nginx@21f92cbd63ab495d8fc44d54dabc4815c88d37697b3f8b757ca8e51ef178a2e7
```

Yay! It's verified. But in order to make the public key accessible by Flux, we need to create a Kubernetes secret to store the public key:

```shell
kubectl -n flux-system create secret generic cosign-pub \
  --from-file=cosign.pub=cosign.pub
```

Now, we can use it in our Flux configuration. The rest of the steps are the same as the previous section. For the sake of simplicity, we won't repeat them here other than the _HelmRepository_ and _HelmRelease_ resources' creation steps.

Let's create the _HelmRepository_ resource first:

```shell
flux create source helm $USER-charts\
    --url=oci://ghcr.io/$USER \
    --interval=10m \
    --export > ./clusters/my-cluster/nginx-helmrepository.yaml
```

Let's move on with creating the _HelmRelease_ resource:

```shell
flux create helmrelease nginx \
    --source=HelmRepository/$USER-charts \
    --chart=nginx \
    --interval=10m \
    --release-name nginx \
    --target-namespace=default \
    --export > ./clusters/my-cluster/nginx-helmrelease.yaml
```

Don't forget to run the following command to add the `verify` section to the _HelmRelease_ resource' `.spec.chart.spec` section  to enable verification:

```shell
yq e '.spec.chart.spec|=({"verify": { "provider": "cosign", "secretRef": { "name": "cosign-pub" } } } +.)' ./clusters/my-cluster/nginx-helmrelease.yaml
```

This command above will add the following part to the `HelmRelease` resource's `.spec.chart.spec` section:

```yaml
verify:
  provider: cosign
  secretRef:
    name: cosign-pub
```

That's all you need to do folks!

Congratulations! You have successfully signed your Helm chart with _cosign_ with key-based approach and used it with Flux.
