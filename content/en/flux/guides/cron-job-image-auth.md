---
title: "Configure image automation authentication"
linkTitle: "Configure image automation authentication"
description: "How to use cron jobs to sync image repository credentials."
weight: 90
---

## Image Repository Authentication

While [native authentication mechanisms](../components/image/imagerepositories.md#provider)
are available, using a cron job is the preferred way of syncing image repository credentials for
multi-tenancy as the controller cannot natively get access to the image repository.

### AWS Elastic Container Registry

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
apiVersion: batch/v1
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
          - image: ghcr.io/fluxcd/flux-cli:v0.25.2
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
            - /bin/sh
            - -ce
            - |-
              kubectl create secret docker-registry $SECRET_NAME \
                --dry-run=client \
                --docker-server="$ECR_REGISTRY" \
                --docker-username=AWS \
                --docker-password="$(cat /token/ecr-token)" \
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
kubectl create job --from=cronjob/ecr-credentials-sync -n flux-system ecr-credentials-sync-init
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
apiVersion: batch/v1
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
kubectl create job --from=cronjob/gcr-credentials-sync -n flux-system gcr-credentials-sync-init
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
or [Sealed Secrets](sealed-secrets.md) , commit and push the encrypted file to git.

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

As a pre-requisite, your AKS cluster will need [AAD Pod Identity](/flux/components/image/imagerepositories/#aad-pod-identity) installed.

Once we have AAD Pod Identity installed, we can create a Deployment that frequently refreshes an image pull secret into
our desired Namespace.

Create a directory in your control repository and save this `kustomization.yaml`:

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- https://github.com/fluxcd/flux2/manifests/integrations/registry-credentials-sync/azure?ref=main
patches:
  - path: config-map-patch.yaml
    target:
      kind: ConfigMap
      name: credentials-sync
  - path: azure-identity-patch.yaml
    target:
      kind: AzureIdentity
      name: credentials-sync
```

Save and configure the following patches -- note the instructional comments for configuring matching Azure resources:

```yaml
# config-map-patch.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: credentials-sync
data:
  ACR_NAME: my-registry
  KUBE_SECRET: my-registry  # does not yet exist -- will be created in the same Namespace
  SYNC_PERIOD: "3600"  # ACR tokens expire every 3 hours; refresh faster than that
```

```yaml
# azure-identity-patch.yaml

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
or [Sealed Secrets](sealed-secrets.md), then commit and push the encrypted file to git.

This Secret should be in the same Namespace as your flux `ImageRepository` object.
Update the `ImageRepository.spec.secretRef` to point to it.

It is also possible to create [Repository Scoped Tokens](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions).

{{% alert color="info" %}}
Note that this feature is in preview and does have limitations.
{{% /alert %}}
