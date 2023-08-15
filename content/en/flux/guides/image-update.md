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
Please note that you need to delete the `flux-system` secret before rerunning bootstrap
to [rotate the deploy key](/flux/installation/configuration/deploy-key-rotation/).
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
Please see the [installation guide](../installation.md) for more details.
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
--interval=5m \
--export > ./clusters/my-cluster/podinfo-registry.yaml
```

The above command generates the following manifest:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
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
apiVersion: image.toolkit.fluxcd.io/v1beta2
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
have a look at [the examples](#imagepolicy-examples).
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
NAME    LAST SCAN                       SUSPENDED       READY   MESSAGE
podinfo 2020-12-13T17:51:48+02:00       False           True    successful scan: found 13 tags
```

For debugging purposes, to see a sample of the tags scanned by the
`ImageRepository`, a list of ten latest tags scanned by the `ImageRepository`
resource can be seen in the status of the resource:

```sh
$ kubectl -n flux-system describe imagerepositories podinfo
...
Status:
  Canonical Image Name:  ghcr.io/stefanprodan/podinfo
  Last Scan Result:
    Latest Tags:
      latest
      6.3.3
      6.3.2
      6.3.1
      6.3.0
      6.2.3
      6.2.2
      6.2.1
      6.2.0
      6.1.8
    Scan Time:  2020-12-13T17:51:48Z
    Tag Count:  13
  Observed Exclusion List:
    ^.*\.sig$
  Observed Generation:  2
...
```

Find which image tag matches the policy semver range with:

```sh
$ flux get image policy podinfo
NAME    LATEST IMAGE                            READY   MESSAGE
podinfo ghcr.io/stefanprodan/podinfo:5.0.3      True    Latest image tag for 'ghcr.io/stefanprodan/podinfo' resolved to 5.0.3
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
--interval=30m \
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
  interval: 30m
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
apiVersion: kustomize.toolkit.fluxcd.io/v1
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
Flux's [GitHub Actions Auto PR](/flux/use-cases/gh-actions-auto-pr) example
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
apiVersion: notification.toolkit.fluxcd.io/v1
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

* [Automated authentication](../components/image/imagerepositories.md#provider)
mechanisms (where the controller retrieves the credentials itself and is only
available for the three major cloud providers), or
* a [`CronJob`](cron-job-image-auth.md) which does not rely on native platform support in Flux,
  (instead storing credentials as Kubernetes secrets which are periodically refreshed.)

Native authentication mechanisms have been implemented in Flux for the three major
cloud providers, but they have to be set in the individual `ImageRepository`
resources. Please see individual sections on how to do this.

## ImagePolicy Examples

Select the latest `main` branch build tagged as `${GIT_BRANCH}-${GIT_SHA:0:7}-$(date +%s)` (numerical):

```yaml
kind: ImagePolicy
spec:
  filterTags:
    pattern: '^main-[a-fA-F0-9]+-(?P<ts>.*)'
    extract: '$ts'
  policy:
    numerical:
      order: asc
```

A more strict filter would be `^main-[a-fA-F0-9]+-(?P<ts>[1-9][0-9]*)`.
Before applying policies in-cluster, you can validate your filters using
a [Go regular expression tester](https://regoio.herokuapp.com)
or [regex101.com](https://regex101.com/).

Select the latest stable version (semver):

```yaml
kind: ImagePolicy
spec:
  policy:
    semver:
      range: '>=1.0.0'
```

Select the latest stable patch version in the 1.x range (semver):

```yaml
kind: ImagePolicy
spec:
  policy:
    semver:
      range: '>=1.0.0 <2.0.0'
```

Select the latest version including pre-releases (semver):

```yaml
kind: ImagePolicy
spec:
  policy:
    semver:
      range: '>=1.0.0-0'
```

Select the latest release candidate (semver):

```yaml
kind: ImagePolicy
spec:
  filterTags:
    pattern: '.*-rc.*'
  policy:
    semver:
      range: '^1.x-0'
```

Select the latest release tagged as `RELEASE.<RFC3339-TIMESTAMP>`
e.g. [Minio](https://hub.docker.com/r/minio/minio) (alphabetical):

```yaml
kind: ImagePolicy
spec:
  filterTags:
    pattern: '^RELEASE\.(?P<timestamp>.*)Z$'
    extract: '$timestamp'
  policy:
    alphabetical:
      order: asc
```
