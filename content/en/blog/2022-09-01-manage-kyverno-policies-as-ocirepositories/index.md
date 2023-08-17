---
author: developer-guy
date: 2022-09-01 11:30:00+00:00
title: Managing Kyverno Policies as OCI Artifacts with OCIRepository Sources
description: "We will give you a real-world example of the newest feature in Flux v0.32 called OCIRepository sources to show you how you can leverage this feature to manage Kyverno policies as OCI Artifacts."
url: /blog/2022/08/manage-kyverno-policies-as-ocirepositories
tags: [oci]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

The Flux team has released a new version of Flux [v0.32](https://github.com/fluxcd/flux2/releases/tag/v0.32.0) that includes fantastic features. One of them is OCI Repositories feature that allows us to store and distribute a wide variety of sources such as Kubernetes manifests, Kustomize overlays, and Terraform modules as [OCI (Open Container Initiative) artifacts](https://github.com/opencontainers/artifacts#project-introduction-and-scope). Furthermore, the Flux team got us even more excited because they are planning to verify the authenticity of the OCI artifacts before they get applied into Kubernetes by integrating Cosign, which is one of the most significant projects from the @projectsigstore community that help us to sign and verify OCI images, blobs, etc. please see the [issue](https://github.com/fluxcd/source-controller/issues/863) to get more details about the plan.

> ⚠️ **Note:** You can read the RFC of this feature [here](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci).

{{< tweet user="stefanprodan" id="1557754198648913921" >}}

Today’s blog post is all about a quick tour of this feature and will give you a real-world example of it to show you how you can leverage this feature to manage Kyverno policies as OCI Artifacts. It is worth saying that this topic has been discussed for a while in the Kyverno community, too. There is an ongoing [issue](https://github.com/kyverno/KDP/pull/19) about packaging and distributing Kyverno policies as OCI Artifacts through its CLI. Also, there is a chance to move that logic into Kyverno’s core.

But for those who might not be familiar enough with OCI artifacts (including me), it’s worth explaining what the OCI Artifacts are before jumping into the details. OCI Artifacts gives you the power of storing and distributing other types of data (nearly anything), such as Kubernetes deployment files, [Helm Charts](https://helm.sh/), [and CNAB](https://cnab.io/), in addition to container images via OCI registries. And today, we’ll be using this feature for Kyverno policies. To be more precise, OCI Artifacts are not a new specification, format, or API. It just utilizes the existent [OCI manifest](https://github.com/opencontainers/image-spec/blob/master/manifest.md) and [OCI index](https://github.com/opencontainers/image-spec/blob/master/image-index.md) definitions. Hence, we can quickly start using the same client tooling, such as a crane, skopeo, etc., and distribute them using OCI registries, thanks to the [OCI distribution-spec](https://github.com/opencontainers/distribution-spec/). Because OCI Artifacts does not change anything related to the specs, it only expands them to give people (artifact authors) power to define their content types. It is more like a generic definition for determining what can be stored in an OCI registry and consumed by clients.

The Flux CLI generates a single layer OCI image for storing things. As you can use some other tools to generate an OCI image with multiple layers in it, you can use the [Layer Selection](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci#layer-selection) feature that Flux provides to select the layers you want to use in the OCI image. If the layer selector matches more than one layer, the first layer matching the specified media type will be used. Note that Flux requires that the OCI layer is compressed in the tar+gzip format.

{{< imgproc meme-featured Resize 400x >}}
{{< /imgproc >}}

Today, we’ll leverage the OCI Repositories feature to apply Kyverno policies stored in an OCI registry into the Kubernetes cluster.

First, we need to install Flux CLI, please see the [installation](/flux/installation/) page for more details.

Next, we should have a Kubernetes cluster running. We’ll be using [KinD](https://kind.sigs.k8s.io/docs/user/quick-start#configuring-your-kind-cluster) for this purpose.

```shell
kind create cluster
```

Once the cluster has been provisioned successfully, we need to install Flux components into it by simply running the command below:

```shell
$ flux bootstrap github \
  --owner=developer-guy \
  --repository=flux-kyverno-policies \
  --path=clusters/local \
  --personal
```

> ⚠️ **Note:** Don't forget to change the values with your own details!

This command will install Flux and create necessary files for us and push them into the repository.

Next, we should install Kyverno by using a GitOps approach with Flux. In order to do that, we use the following resources:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: kyverno-controller
  namespace: flux-system
spec:
  interval: 30m
  url: https://github.com/kyverno/kyverno
  ignore: |
    /*
    !/config/
  ref:
    semver: "1.x"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: kyverno-controller
  namespace: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: kyverno-controller
  serviceAccountName: kustomize-controller
  path: ./config/release
  prune: true
  wait: true
  timeout: 5m
```

Do not forget to check whether everything works fine before moving into the next steps:

```shell
$ flux get kustomizations kyverno-controller
NAME                    REVISION        SUSPENDED       READY   MESSAGE
kyverno-controller      v1.7.3/f2b63ce  False           True    Applied revision: v1.7.3/f2b63ce
```

Now, we are ready to create an OCI image to store my Kyverno policies.

> ⚠️  You can find all the code examples in [GitHub](https://github.com/developer-guy/flux-kyverno-policies).

In order to do that, we will clone our repository that holds the Kyverno policies and create an OCI artifact to store them.

> ⚠️ We are expecting that some other team like DevSecOps will be responsible for maintaining and publishing the policies to our registry.

```shell
$ git clone https://github.com/developer-guy/my-kyverno-policies.git
$ cd my-kyverno-policies
$ flux push artifact oci://ghcr.io/developer-guy/policies:v1.0.0 \
  --path="." \
  --source="$(git config --get remote.origin.url)" \
  --revision="$(git branch --show-current)/$(git rev-parse HEAD)"
► pushing artifact to ghcr.io/developer-guy/policies:v1.0.0
✔ artifact successfully pushed to ghcr.io/developer-guy/policies@sha256:56e853e3c5c02139c840b7f5c89a02f63ede8dc498ed3925a52360032aa49e60
```

> ⚠️ **Note:** Don't forget to change the values with your own details!

Last but not least, we need to create an `OCIRepository` resource that points to my OCI artifact:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: kyverno-policies
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/developer-guy/policies
  ref:
    semver: "v1.x"
  secretRef:
    name: ghcr-auth
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: kyverno-policies
  namespace: flux-system
spec:
  sourceRef:
    kind: OCIRepository
    name: kyverno-policies
  interval: 60m
  retryInterval: 5m
  path: ./
  prune: true
  wait: true
  timeout: 2m
  dependsOn:
    - name: kyverno-controller
  patches: # enforce all policies
    - patch: |
        - op: replace
          path: /spec/validationFailureAction
          value: enforce
      target:
        kind: ClusterPolicy
```

I'd like to highlight some key points about the resources above. Here in `OCIRepository` resource, we are using [SemVer](/flux/components/source/ocirepositories/#semver-example) to select the policies that we want to apply. `.spec.ref` is an optional field to specify the OCI reference to resolve and watch for changes. If not specified, the latest version of the repository will be used. You can reach out to the complete list of references supported in Flux, here is the [link](/flux/components/source/ocirepositories/#reference) for you.

Also, in the `Kustomization` resource, we are using `.spec.patches` to apply patches to the policies that we want to enforce. We are using `op: replace` to replace the existing value of the field with the new one. `path` is the path to the field that we want to replace. `value` is the value of the field that we want to replace. To get more detail about the `Patches`, please see the [link](/flux/components/kustomize/kustomization/#patches).

Last but not least, we are specifying an explicit dependencies for the `Kustomization` resource by using `dependsOn` keyword that ensures the Kyverno deployment is ready before applying the policies. This is important because Kyverno needs to be installed before applying the policies. Otherwise, the policies won't be used because CRD (Custom Resource Definitions) won't exist until Kyverno works. You can learn more about the dependencies of `Kustomization` resource, [here](/flux/components/kustomize/kustomization/#dependencies).

Now, we can apply these manifests by committing and pushing them to the repository and letting Flux take care of the rest but still, one little step left that we need to do, which is authentication.

> ⚠️  Don't forget, the authentication part is only needed when the OCI artifact is not publicly accessible. If your image has publicy available, you can skip that part.

You might notice a `secretRef` section in the `OCIRepository` resource. We should create this secret because Flux should be able to pull my container image. To do that, we should follow the documentation.

```shell
$ flux create secret oci ghcr-auth \
  --url=ghcr.io \
  --username=developer-guy \
  --password=${GITHUB_PAT}
► oci secret 'ghcr-auth' created in 'flux-system' namespace
```

Once everything is completed, you should be able to see the following output:

```shell
$ kubectl get clusterpolicies
NAME                 BACKGROUND   ACTION    READY
require-base-image   true         enforce   true
```

This is what we expected to happen, whee!🕺🏻

This is an exciting policy, though, if you want to learn more about it, I wrote a [blog post](https://nirmata.com/2022/07/14/securing_base_images/) that explains what the base image concept refers to and how we can enforce policies related to them.

As you can see, this feature is quite promising and easy to use. I hope you enjoyed it, and please stay tuned because there are more features on the way you don’t want to miss.

Thanks for reading.
