---
title: "Automate image updates to Git"
linkTitle: "Automate image updates to Git"
description: "Automate container image updates to Git with Flux."
weight: 80
card:
  name: tasks
  weight: 20
---

This guide walks you through configuring container image scanning and deployment rollouts with Flux.

For a container image you can configure Flux to:

- scan the container registry and fetch the image tags
- select the latest tag based on the defined policy (semver, calver, regex)
- replace the tag in Kubernetes manifests (YAML format)
- checkout a branch, commit and push the changes to the remote Git repository
- apply the changes in-cluster and rollout the container image

For production environments, this feature allows you to automatically deploy application patches
(CVEs and bug fixes), and keep a record of all deployments in Git history.

**Production CI/CD workflow**

* DEV: push a bug fix to the app repository
* DEV: bump the patch version and release e.g. `v1.0.1`
* CI: build and push a container image tagged as `registry.domain/org/app:v1.0.1`
* CD: pull the latest image metadata from the app registry (Flux image scanning)
* CD: update the image tag in the app manifest to `v1.0.1` (Flux cluster to Git reconciliation)
* CD: deploy `v1.0.1` to production clusters (Flux Git to cluster reconciliation)

For staging environments, this features allow you to deploy the latest build of a branch,
without having to manually edit the app deployment manifest in Git.

**Staging CI/CD workflow**

* DEV: push code changes to the app repository `main` branch
* CI: build and push a container image tagged as `${GIT_BRANCH}-${GIT_SHA:0:7}-$(date +%s)`
* CD: pull the latest image metadata from the app registry (Flux image scanning)
* CD: update the image tag in the app manifest to `main-2d3fcbd-1611906956` (Flux cluster to Git reconciliation)
* CD: deploy `main-2d3fcbd-1611906956` to staging clusters (Flux Git to cluster reconciliation)

## Prerequisites

You will need a Kubernetes cluster version 1.16 or newer and kubectl version 1.18.
For a quick local test, you can use [Kubernetes kind](https://kind.sigs.k8s.io/docs/user/quick-start/).
Any other Kubernetes setup will work as well.

In order to follow the guide you'll need a GitHub account and a
[personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
that can create repositories (check all permissions under `repo`).

Export your GitHub personal access token and username:

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
```

## Install Flux

{{% alert color="info" title="Enable image automation components" %}}
If you bootstrapped Flux before, you need to add
`--components-extra=image-reflector-controller,image-automation-controller` to your
bootstrapping routine as image automation components are not installed by default.
{{% /alert %}}

Install Flux with the image automation components:

```sh
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --repository=flux-image-updates \
  --branch=main \
  --path=clusters/my-cluster \
  --read-write-key \
  --personal
```

The bootstrap command creates a repository if one doesn't exist, and commits the manifests for the
Flux components to the default branch at the specified path. It then configures the target cluster to
synchronize with the specified path inside the repository.

{{% alert color="info" title="GitLab and other Git platforms" %}}
You can install Flux and bootstrap repositories hosted on GitLab, BitBucket, Azure DevOps and
any other Git provider that support SSH or token-based authentication.
When using SSH, make sure the deploy key is configured with write access `--read-write-key`.
Please see the [installation guide](../installation/_index.md) for more details.
{{% /alert %}}

## Deploy a demo app

We'll be using a tiny webapp called [podinfo](https://github.com/stefanprodan/podinfo) to
showcase the image update feature.

Clone your repository with:

```sh
git clone https://github.com/$GITHUB_USER/flux-image-updates
cd flux-image-updates
```

Create a deployment for [podinfo](https://github.com/stefanprodan/podinfo) inside `clusters/my-cluster`:

```sh
cat <<EOF > ./clusters/my-cluster/podinfo-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: default
spec:
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfod
          image: ghcr.io/stefanprodan/podinfo:5.0.0
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 9898
              protocol: TCP
EOF
```

Commit and push changes to main branch:

```sh
git add -A && \
git commit -m "add podinfo deployment" && \
git push origin main
```

Tell Flux to pull and apply the changes or wait one minute for Flux to detect the changes on its own:

```sh
flux reconcile kustomization flux-system --with-source
```

Print the podinfo image deployed on your cluster:

```sh
$ kubectl get deployment/podinfo -oyaml | grep 'image:'
image: ghcr.io/stefanprodan/podinfo:5.0.0
```

## Configure image scanning

Create an `ImageRepository` to tell Flux which container registry to scan for new tags:

```sh
flux create image repository podinfo \
--image=ghcr.io/stefanprodan/podinfo \
--interval=1m \
--export > ./clusters/my-cluster/podinfo-registry.yaml
```

The above command generates the following manifest:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 1m0s
```

For private images, you can create a Kubernetes secret
in the same namespace as the `ImageRepository` with
`kubectl create secret docker-registry`. Then you can configure
Flux to use the credentials by referencing the Kubernetes secret
in the `ImageRepository`:

```yaml
kind: ImageRepository
spec:
  secretRef:
    name: regcred
```

{{% alert color="info" title="Storing secrets in Git" %}}
Note that if you want to store the image pull secret in Git,  you can encrypt
the manifest with [Mozilla SOPS](mozilla-sops.md) or [Sealed Secrets](sealed-secrets.md).
{{% /alert %}}

Create an `ImagePolicy` to tell Flux which semver range to use when filtering tags:

```sh
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=5.0.x \
--export > ./clusters/my-cluster/podinfo-policy.yaml
```

The above command generates the following manifest:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: podinfo
  policy:
    semver:
      range: 5.0.x
```

A semver range that includes stable releases can be defined with
`1.0.x` (patch versions only) or `>=1.0.0 <2.0.0` (minor and patch versions).
If you want to include pre-release e.g. `1.0.0-rc.1`,
you can define a range like: `^1.x-0` or `>1.0.0-rc <2.0.0-rc`.

{{% alert color="info" title="Other policy examples" %}}
For policies that make use of CalVer, build IDs or alphabetical sorting,
have a look at [the examples](../components/image/imagepolicies.md#examples).
{{% /alert %}}

Commit and push changes to main branch:

```sh
git add -A && \
git commit -m "add podinfo image scan" && \
git push origin main
```

Tell Flux to pull and apply changes:

```sh
flux reconcile kustomization flux-system --with-source
```

Wait for Flux to fetch the image tag list from GitHub container registry:

```sh
$ flux get image repository podinfo
NAME   	READY	MESSAGE                       	LAST SCAN
podinfo	True 	successful scan, found 13 tags	2020-12-13T17:51:48+02:00
```

Find which image tag matches the policy semver range with:

```sh
$ flux get image policy podinfo
NAME   	READY	MESSAGE                   
podinfo	True 	Latest image tag for 'ghcr.io/stefanprodan/podinfo' resolved to: 5.0.3
```

## Configure image updates

Edit the `podinfo-deployment.yaml` and add a marker to tell Flux which policy to use when updating the container image:

```yaml
spec:
  containers:
  - name: podinfod
    image: ghcr.io/stefanprodan/podinfo:5.0.0 # {"$imagepolicy": "flux-system:podinfo"}
```

Create an `ImageUpdateAutomation` to tell Flux which Git repository to write image updates to:

```sh
flux create image update flux-system \
--git-repo-ref=flux-system \
--git-repo-path="./clusters/my-cluster" \
--checkout-branch=main \
--push-branch=main \
--author-name=fluxcdbot \
--author-email=fluxcdbot@users.noreply.github.com \
--commit-template="{{range .Updated.Images}}{{println .}}{{end}}" \
--export > ./clusters/my-cluster/flux-system-automation.yaml
```

The above command generates the following manifest:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcdbot@users.noreply.github.com
        name: fluxcdbot
      messageTemplate: '{{range .Updated.Images}}{{println .}}{{end}}'
    push:
      branch: main
  update:
    path: ./clusters/my-cluster
    strategy: Setters
```

Commit and push changes to main branch:

```sh
git add -A && \
git commit -m "add image updates automation" && \
git push origin main
```

Note that the `ImageUpdateAutomation` runs all the policies found in its namespace at the specified interval.

Tell Flux to pull and apply changes:

```sh
flux reconcile kustomization flux-system --with-source
```

In a couple of seconds, Flux will push a commit to your repository with
the latest image tag that matches the podinfo policy:

```sh
$ git pull && cat clusters/my-cluster/podinfo-deployment.yaml | grep "image:"
image: ghcr.io/stefanprodan/podinfo:5.0.3 # {"$imagepolicy": "flux-system:podinfo"}
```

Wait for Flux to apply the latest commit on the cluster and verify that podinfo was updated to `5.0.3`:

```sh
$ watch "kubectl get deployment/podinfo -oyaml | grep 'image:'"
image: ghcr.io/stefanprodan/podinfo:5.0.3
```

You can check the status of the image automation objects with:

```sh
flux get images all --all-namespaces
```

## Configure image update for custom resources

Besides Kubernetes native kinds (Deployment, StatefulSet, DaemonSet, CronJob),
Flux can be used to patch image references in any Kubernetes custom resource
stored in Git.

The image policy marker format is:

* `{"$imagepolicy": "<policy-namespace>:<policy-name>"}`
* `{"$imagepolicy": "<policy-namespace>:<policy-name>:tag"}`
* `{"$imagepolicy": "<policy-namespace>:<policy-name>:name"}`

These markers are placed inline in the target YAML, as a comment.  The "Setter" strategy refers to
[kyaml setters](https://github.com/fluxcd/flux2/discussions/107#discussioncomment-82746)
which Flux can find and replace during reconciliation, when directed to do so by an `ImageUpdateAutomation` 
like the one [above](#configure-image-updates).

Here are some examples of using this marker in a variety of Kubernetes resources.

`HelmRelease` example:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
spec:
  values:
    image:
      repository: ghcr.io/stefanprodan/podinfo # {"$imagepolicy": "flux-system:podinfo:name"}
      tag: 5.0.0  # {"$imagepolicy": "flux-system:podinfo:tag"}
```

Tekton `Task` example:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: golang
  namespace: default
spec:
  steps:
    - name: golang
      image: docker.io/golang:1.15.6 # {"$imagepolicy": "flux-system:golang"}
```

Flux `Kustomization` example:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: podinfo
  namespace: default
spec:
  images:
    - name: ghcr.io/stefanprodan/podinfo
      newName: ghcr.io/stefanprodan/podinfo # {"$imagepolicy": "flux-system:podinfo:name"}
      newTag: 5.0.0 # {"$imagepolicy": "flux-system:podinfo:tag"}
```

Kustomize config (`kustomization.yaml`) example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
images:
- name: ghcr.io/stefanprodan/podinfo
  newName: ghcr.io/stefanprodan/podinfo # {"$imagepolicy": "flux-system:podinfo:name"}
  newTag: 5.0.0 # {"$imagepolicy": "flux-system:podinfo:tag"}
```

## Push updates to a different branch

With `.spec.git.push.branch` you can configure Flux to push the image updates to different branch
than the one used for checkout. If the specified branch doesn't exist, Flux will create it for you.

```yaml
kind: ImageUpdateAutomation
metadata:
  name: flux-system
spec:  
  git:
    checkout:
      ref:
        branch: main
    push:
      branch: flux-image-updates
```

You can use CI automation e.g. GitHub Actions such as
Flux's [GitHub Actions Auto PR](/docs/workflows/gh-actions-auto-pr) example
to open a pull request against the checkout branch.

This way you can manually approve the image updates before they are applied on your clusters.

## Configure the commit message

The `.spec.git.commit.messageTemplate` field is a string which is used as a template for the commit message.

The message template is a [Go text template](https://golang.org/pkg/text/template/) that
lets you range over the objects and images e.g.:

```yaml
kind: ImageUpdateAutomation
metadata:
  name: flux-system
spec:
  git:
    commit:
      messageTemplate: |
        Automated image update

        Automation name: {{ .AutomationObject }}

        Files:
        {{ range $filename, $_ := .Updated.Files -}}
        - {{ $filename }}
        {{ end -}}

        Objects:
        {{ range $resource, $_ := .Updated.Objects -}}
        - {{ $resource.Kind }} {{ $resource.Name }}
        {{ end -}}

        Images:
        {{ range .Updated.Images -}}
        - {{.}}
        {{ end -}}
      author:
        email: fluxcdbot@users.noreply.github.com
        name: fluxcdbot
```

## Trigger image updates with webhooks

You may want to trigger a deployment
as soon as a new image tag is pushed to your container registry.
In order to notify the image-reflector-controller about new images,
you can [setup webhook receivers](webhook-receivers.md).

First generate a random string and create a secret with a `token` field:

```sh
TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
echo $TOKEN

kubectl -n flux-system create secret generic webhook-token \	
--from-literal=token=$TOKEN
```

Define a receiver for DockerHub:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta1
kind: Receiver
metadata:
  name: podinfo
  namespace: flux-system
spec:
  type: dockerhub
  secretRef:
    name: webhook-token
  resources:
    - kind: ImageRepository
      name: podinfo
```

The notification-controller generates a unique URL using the provided token and the receiver name/namespace.

Find the URL with:

```sh
$ kubectl -n flux-system get receiver/podinfo

NAME      READY   STATUS
podinfo   True    Receiver initialised with URL: /hook/bed6d00b5555b1603e1f59b94d7fdbca58089cb5663633fb83f2815dc626d92b
```

Log in to DockerHub web interface, go to your image registry Settings and select Webhooks.
Fill the form "Webhook URL" by composing the address using the receiver
LB and the generated URL `http://<LoadBalancerAddress>/<ReceiverURL>`.

{{% alert color="info" title="Other receivers" %}}
Besides DockerHub, you can define receivers for **Harbor**, **Quay**, **Nexus**, **GCR**,
and any other system that supports webhooks e.g. GitHub Actions, Jenkins, CircleCI, etc.
See the [Receiver CRD docs](../components/notification/receiver.md) for more details.
{{% /alert %}}

## Incident management

### Suspend automation

During an incident you may wish to stop Flux from pushing image updates to Git.

You can suspend the image automation directly in-cluster:

```sh
flux suspend image update flux-system
```

Or by editing the `ImageUpdateAutomation` manifest in Git:

```yaml
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  suspend: true
```

Once the incident is resolved, you can resume automation with:

```sh
flux resume image update flux-system
```

If you wish to pause the automation for a particular image only,
you can suspend/resume the image scanning:

```sh
flux suspend image repository podinfo
```

### Revert image updates

Assuming you've configured Flux to update an app to its latest stable version:

```sh
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=">=5.0.0"
```

If the latest version e.g. `5.0.1` causes an incident in production, you can tell Flux to 
revert the image tag to a previous version e.g. `5.0.0` with:

```sh
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=5.0.0
```

Or by changing the semver range in Git:

```yaml
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  policy:
    semver:
      range: 5.0.0
```

Based on the above configuration, Flux will patch the podinfo deployment manifest in Git
and roll out `5.0.0` in-cluster.

When a new version is available e.g. `5.0.2`, you can update the policy once more
and tell Flux to consider only versions greater than `5.0.1`:

```sh
flux create image policy podinfo \
--image-ref=podinfo \
--select-semver=">5.0.1"
```

## ImageRepository cloud providers authentication

Two methods are available for authenticating container registers as
`ImageRepository` resources in Flux:

* Automated authentication mechanisms (where the controller retrieves the credentials itself 
and is only available for the three major cloud providers), or
* a [`CronJob`](cron-job-image-auth.md) which does not rely on native platform support in Flux,
  (instead storing credentials as Kubernetes secrets which are periodically refreshed.)

Native authentication mechanisms have been implemented in Flux for the three major
cloud providers, but it needs to enabled with a flag. Please see individual sections
on how to do this.

{{% alert color="info" title="Workarounds" color="warning" %}}
Please note that the native authentication feature is still experimental and using
cron jobs to refresh credentials is still the recommended method especially for multi-tenancy
where tenants on the same cluster don't trust each other. Check [cron job documentation](cron-job-image-auth.md) for
common examples for the most popular cloud provider docker registries.
{{% /alert %}}

### Using Native AWS ECR Auto-Login

There is native support for the AWS Elastic Container Registry available since 
`image-reflector-controller` [v0.13.0](https://github.com/fluxcd/image-reflector-controller/blob/main/CHANGELOG.md#0130)
which was released with Flux release v0.19. This depends on setting the `--aws-autologin-for-ecr`
flag, which assumes any ECR repositories with IAM roles assigned to the cluster can
be freely shared across any cluster tenants. This flag can be added by including a patch in the `kustomization.yaml` overlay file in your `flux-system`,
similar to the process described in [customize Flux manifests](../installation/_index.md/#customize-flux-manifests):
                        
```yaml
patches:
- target:
    version: v1
    group: apps
    kind: Deployment
    name: image-reflector-controller
    namespace: flux-system
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/args/-
      value: --aws-autologin-for-ecr
```

### Using Native GCP GCR Auto-Login

There is native support for the GCP Google Container Registry available since `image-reflector-controller` [v0.16.0][v0.16.0 image reflector changelog]
which was released with Flux release v0.26.0. This feature is enabled by setting the `--gcp-autologin-for-gcr`
flag. This works with both clusters that have Workload Identity enabled, and those that use the default service account.
This flag can be added by including a patch in the `kustomization.yaml` overlay file in your `flux-system`,
similar to the process described in [customize Flux manifests](../installation/_index.md/#customize-flux-manifests):
                                             
```yaml
patches:
- target:
    version: v1
    group: apps
    kind: Deployment
    name: image-reflector-controller
    namespace: flux-system
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/args/-
      value: --gcp-autologin-for-gcr
 ### add this patch to annotate service account if you are using Workload identity
patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: image-reflector-controller
    namespace: flux-system
    annotations:
      iam.gke.io/gcp-service-account: <gcp-service-account-name>@<PROJECT_ID>.iam.gserviceaccount.com
```

The Artifact Registry service uses the permission `artifactregistry.repositories.downloadArtifacts` that is
located under the Artifact Registry Reader role. If you are using Google Container Registry service, the needed
permission is instead `storage.objects.list` which can be bound as part of the Container Registry Service Agent
role, (or it can be bound separately in your own created role for the least required permission.)

Take a look at [this guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) for more
information about setting up GKE Workload Identity.

### Using Native Azure ACR Auto-Login

There is native support for the Azure Container Registry] available since 
`image-reflector-controller` [v0.16.0][v0.16.0 image reflector changelog]
which was released with Flux release v0.26.0. This feature is enabled by setting the `--azure-autologin-for-acr`
flag, This flag can be added by including a patch in the `kustomization.yaml` overlay file in your `flux-system`,
similar to the process described in [customize Flux manifests](../installation/_index.md/#customize-flux-manifests):

```yaml
patches:
- target:
    version: v1
    group: apps
    kind: Deployment
    name: image-reflector-controller
    namespace: flux-system
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/args/-
      value: --azure-autologin-for-acr
      # Add this if you are using aad pod identity with managed identity
    - op: add 
      path: /spec/template/metadata/labels/aadpodidbinding
      value: <name-of-identity>
```

{{% alert color="info" title="AKS with Managed Identity" %}}
When using managed identity on an AKS cluster, [AAD Pod Identity](https://azure.github.io/aad-pod-identity) has to
be used to give the `image-reflector-controller` pod access to the ACR. To do this, you have to install
`aad-pod-identity` on your cluster, create a managed identity that has access to the container registry (this can
also be the Kubelet identity if it has `AcrPull` role assignment on the ACR), create an `AzureIdentity` and
`AzureIdentityBinding` that describe the managed identity and then label the `image-reflector-controller` pods with
the name of the `AzureIdentity` as shown in the patch above.
Please take a look at [this guide](https://azure.github.io/aad-pod-identity/docs/)
or [this one](https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity) if you want to use AKS
pod-managed identities add-on that is in preview.
{{% /alert %}}

{{% alert title="Migrating from cron-based registry credentials sync" color="warning" %}}
If you are migrating from the [Generating Tokens for Managed Identities [short-lived]](/docs/workflows/cron-job-image-auth/#generating-tokens-for-managed-identities-short-lived) approach, `spec.secretRef` must be removed from your `ImageRepository`!
Failing to do so will, eventually, cause the `image-reflector-controller` to use stale credentials when it tries to get images from the ACR.
{{% /alert %}}

[v0.16.0 image reflector changelog]: https://github.com/fluxcd/image-reflector-controller/blob/main/CHANGELOG.md#0160
