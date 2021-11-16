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

For staging environments, this feature allows you to deploy the latest build of a branch,
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
Please see the [installation guide](../installation/) for more details.
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

{{% alert color="info" title="Semver Ranges" %}}
A semver range that includes stable releases can be defined with
`1.0.x` (patch versions only) or `>=1.0.0 <2.0.0` (minor and patch versions).
If you want to include pre-release e.g. `1.0.0-rc.1`,
you can define a range like: `^1.x-0` or `>1.0.0-rc <2.0.0-rc`.
{{% /alert %}}

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
Flux's [GitHub Actions Auto PR](/docs/use-cases/gh-actions-auto-pr) example
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

If relying on a cloud provider image repository, you might need to do some extra
work in order to configure the ImageRepository resource credentials. Here are
some common examples for the most popular cloud provider docker registries.

{{% alert color="info" title="Workarounds" color="warning" %}}
The examples below are intended as workaround solutions until native
authentication mechanisms are implemented in Flux itself to support this in
a more straightforward manner. There is also an experimental native container
registry support in Flux for the AWS ECR autologin feature, described below.
{{% /alert %}}

### AWS Elastic Container Registry

Two methods are available for authenticating AWS Elastic Container Registries as
`ImageRepository` resources in Flux:

* Experimental Native Auto-Login, or
* a `CronJob` which does not rely on native platform support in Flux,
  (instead storing credentials as Kubernetes secrets which are periodically refreshed.)

#### Using Native AWS ECR Auto-Login

There is [native support for the AWS Elastic Container Registry](https://fluxcd.io/docs/components/image/imagerepositories/#ecr-and-eks),
available since `image-reflector-controller` [v0.13.0](https://github.com/fluxcd/image-reflector-controller/blob/main/CHANGELOG.md#0130)
which was released with Flux release v0.19. This depends on setting the `--aws-autologin-for-ecr`
flag, which assumes any ECR repositories with IAM roles assigned to the cluster can
be freely shared across any cluster tenants.

Put another way, the autologin strategy assumes that there are no important security
boundaries for ECR inside the cluster. For a more isolated configuration, with behavior
that is more consistent with the standard [multi-tenant security model](https://github.com/fluxcd/flux2-multi-tenancy)
of Flux, the guidance that follows should be considered instead.

#### Using CronJob to sync ECR credentials as a Kubernetes secret

The registry authentication credentials for ECR expire every 12 hours.
Considering this limitation, one needs to ensure the credentials are being
refreshed before expiration so that the controller can rely on them for
authentication.

The solution proposed is to create a cronjob that runs every 6 hours which would
re-create the `docker-registry` secret using a new token.

Edit and save the following snippet to a file
`./clusters/my-cluster/ecr-sync.yaml`, commit and push it to git.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
rules:
- apiGroups: [""]
  resources:
  - secrets
  verbs:
  - get
  - create
  - patch
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
subjects:
- kind: ServiceAccount
  name: ecr-credentials-sync
roleRef:
  kind: Role
  name: ecr-credentials-sync
  apiGroup: ""
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
  # Uncomment and edit if using IRSA
  # annotations:
  #   eks.amazonaws.com/role-arn: <role arn>
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
spec:
  suspend: false
  schedule: 0 */6 * * *
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ecr-credentials-sync
          restartPolicy: Never
          volumes:
          - name: token
            emptyDir:
              medium: Memory
          initContainers:
          - image: amazon/aws-cli
            name: get-token
            imagePullPolicy: IfNotPresent
            # You will need to set the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables if not using
            # IRSA. It is recommended to store the values in a Secret and load them in the container using envFrom.
            # envFrom:
            # - secretRef:
            #     name: aws-credentials
            env:
            - name: REGION
              value: us-east-1 # change this if ECR repo is in a different region
            volumeMounts:
            - mountPath: /token
              name: token
            command:
            - /bin/sh
            - -ce
            - aws ecr get-login-password --region ${REGION} > /token/ecr-token
          containers:
          - image: bitnami/kubectl
            name: create-secret
            imagePullPolicy: IfNotPresent
            env:
            - name: SECRET_NAME
              value: ecr-credentials
            - name: ECR_REGISTRY
              value: <account id>.dkr.ecr.<region>.amazonaws.com # fill in the account id and region
            volumeMounts:
            - mountPath: /token
              name: token
            command:
            - /bin/bash
            - -ce
            - |-
              kubectl create secret docker-registry $SECRET_NAME \
                --dry-run=client \
                --docker-server="$ECR_REGISTRY" \
                --docker-username=AWS \
                --docker-password="$(</token/ecr-token)" \
                -o yaml | kubectl apply -f -
```

{{% alert color="info" title="Using IAM Roles for Service Accounts (IRSA)" %}}
If using IRSA, make sure the role attached to the service account has
readonly access to ECR. The AWS managed policy
`arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly` can be attached
to the role.
{{% /alert %}}

Since the cronjob will not create a job right away, after applying the manifest,
you can manually create an init job using the following command:

```sh
$ kubectl create job --from=cronjob/ecr-credentials-sync -n flux-system ecr-credentials-sync-init
```

After the job runs, a secret named `ecr-credentials` should be created. Use this
name in your ECR ImageRepository resource manifest as the value for
`.spec.secretRef.name`.

```yaml
spec:
  secretRef:
    name: ecr-credentials
```

### GCP Container Registry

#### Using access token [short-lived]

{{% alert color="info" title="Workload Identity" %}}
Please ensure that you enable workload identity for your cluster, create a GCP service account that has
access to the container registry and create an IAM policy binding between the GCP service account and
the Kubernetes service account so that the pods created by the cronjob can access GCP APIs and get the token.
Take a look at [this guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
{{% /alert %}}

The access token for GCR expires hourly.
Considering this limitation, one needs to ensure the credentials are being
refreshed before expiration so that the controller can rely on them for
authentication.

The solution proposed is to create a cronjob that runs every 45 minutes which would
re-create the `docker-registry` secret using a new token.

Edit and save the following snippet to a file
`./clusters/my-cluster/gcr-sync.yaml`, commit and push it to git.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: gcr-credentials-sync
  namespace: flux-system
rules:
- apiGroups: [""]
  resources:
  - secrets
  verbs:
  - get
  - create
  - patch
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: gcr-credentials-sync
  namespace: flux-system
subjects:
- kind: ServiceAccount
  name: gcr-credentials-sync
roleRef:
  kind: Role
  name: gcr-credentials-sync
  apiGroup: ""
---
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: <name-of-service-account>@<project-id>.iam.gserviceaccount.com
  name: gcr-credentials-sync
  namespace: flux-system
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: gcr-credentials-sync
  namespace: flux-system
spec:
  suspend: false
  schedule: "*/45 * * * *"
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: gcr-credentials-sync
          restartPolicy: Never
          containers:
          - image: google/cloud-sdk
            name: create-secret
            imagePullPolicy: IfNotPresent
            env:
            - name: SECRET_NAME
              value: gcr-credentials
            - name: GCR_REGISTRY
              value: <REGISTRY_NAME> # fill in the registry name e.g gcr.io, eu.gcr.io
            command:
            - /bin/bash
            - -ce
            - |-
              kubectl create secret docker-registry $SECRET_NAME \
                --dry-run=client \
                --docker-server="$GCR_REGISTRY" \
                --docker-username=oauth2accesstoken \
                --docker-password="$(gcloud auth print-access-token)" \
                -o yaml | kubectl apply -f -
```

Since the cronjob will not create a job right away, after applying the manifest,
you can manually create an init job using the following command:

```sh
$ kubectl create job --from=cronjob/gcr-credentials-sync -n flux-system gcr-credentials-sync-init
```

After the job runs, a secret named `gcr-credentials` should be created. Use this
name in your GCR ImageRepository resource manifest as the value for
`.spec.secretRef.name`.

```yaml
spec:
  secretRef:
    name: gcr-credentials
```

#### Using a JSON key [long-lived]

{{% alert color="info" title="Less secure option" color="warning" %}}
From [Google documentation on authenticating container registry](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key)
> A user-managed key-pair that you can use as a credential for a service account.
> Because the credential is long-lived, it is the least secure option of all the available authentication methods.
> When possible, use an access token or another available authentication method to reduce the risk of
> unauthorized access to your artifacts. If you must use a service account key,
> ensure that you follow best practices for managing credentials.
{{% /alert %}}

A Json key doesn't expire, so we don't need a cronjob,
we just need to create the secret and reference it in the ImagePolicy.

First, create a json key file by following this
[documentation](https://cloud.google.com/container-registry/docs/advanced-authentication).
Grant the service account the role of `Container Registry Service Agent`
so that it can access GCR and download the json file.

Then create a secret, encrypt it using [Mozilla SOPS](mozilla-sops.md)
or [Sealed Secrets](sealed-secrets.md) , commit and push the encypted file to git.

```sh
kubectl create secret docker-registry <secret-name> \
  --docker-server=<GCR-REGISTRY> \ # e.g gcr.io
  --docker-username=_json_key \
  --docker-password="$(cat <downloaded-json-file>)"
```

### Azure Container Registry

AKS clusters are not able to pull and run images from ACR by default.
Read [Integrating AKS /w ACR](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration) as a potential pre-requisite
before integrating Flux `ImageRepositories` with ACR.

Note that the resulting ImagePullSecret for Flux could also be specified by Pods within the same Namespace to pull and run ACR images as well.

#### Generating Tokens for Managed Identities [short-lived]

As a pre-requisite, your AKS cluster will need [AAD Pod Identity](../use-cases/azure.md#aad-pod-identity) installed.

Once we have AAD Pod Identity installed, we can create a Deployment that frequently refreshes an image pull secret into
our desired Namespace.

Create a directory in your control repository and save this `kustomization.yaml`:
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- https://github.com/fluxcd/flux2/manifests/integrations/registry-credentials-sync/azure?ref=main
patchesStrategicMerge:
- config-patches.yaml
```
Save and configure the following patch -- note the instructional comments for configuring matching Azure resources:
```yaml
# config-patches.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: credentials-sync
data:
  ACR_NAME: my-registry
  KUBE_SECRET: my-registry  # does not yet exist -- will be created in the same Namespace
  SYNC_PERIOD: "3600"  # ACR tokens expire every 3 hours; refresh faster than that

# Create an identity in Azure and assign it a role to pull from ACR  (note: the identity's resourceGroup should match the desired ACR):
#     az identity create -n acr-sync
#     az role assignment create --role AcrPull --assignee-object-id "$(az identity show -n acr-sync -o tsv --query principalId)"
# Fetch the clientID and resourceID to configure the AzureIdentity spec below:
#     az identity show -n acr-sync -otsv --query clientId
#     az identity show -n acr-sync -otsv --query resourceId
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: credentials-sync  # name must match the stub-resource in az-identity.yaml
  namespace: flux-system
spec:
  clientID: 4ceaa448-d7b9-4a80-8f32-497eaf3d3287
  resourceID: /subscriptions/8c69185e-55f9-4d00-8e71-a1b1bb1386a1/resourcegroups/stealthybox/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-sync
  type: 0  # user-managed identity
```

Verify that `kustomize build .` works, then commit the directory to you control repo.
Flux will apply the Deployment and it will use the AAD managed identity for that Pod to regularly fetch ACR tokens into your configured `KUBE_SECRET` name.
Reference the `KUBE_SECRET` value from any `ImageRepository` objects for that ACR registry.

This example uses the `fluxcd/flux2` github archive as a remote base, but you may copy the [./manifests/integrations/registry-credentials-sync/azure](https://github.com/fluxcd/flux2/tree/main/manifests/integrations/registry-credentials-sync/azure)
folder into your own repository or use a git submodule to vendor it if preferred.

#### Using Static Credentials [long-lived]

{{% alert color="info" %}}
Using a static credential requires a Secrets management solution compatible with your GitOps workflow.
{{% /alert %}}

Follow the official Azure documentation for [Creating an Image Pull Secret for ACR](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes).

Instead of creating the Secret directly into your Kubernetes cluster, encrypt it using [Mozilla SOPS](mozilla-sops.md)
or [Sealed Secrets](sealed-secrets.md), then commit and push the encypted file to git.

This Secret should be in the same Namespace as your flux `ImageRepository` object.
Update the `ImageRepository.spec.secretRef` to point to it.

It is also possible to create [Repository Scoped Tokens](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions).

{{% alert color="info" %}}
Note that this feature is in preview and does have limitations.
{{% /alert %}}
