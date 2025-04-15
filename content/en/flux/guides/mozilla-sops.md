---
title: "Manage Kubernetes secrets with SOPS"
linkTitle: "SOPS"
description: "Manage Kubernetes secrets with SOPS, OpenPGP, Age and Cloud KMS."
weight: 60
---

In order to store secrets safely in a public or private Git repository, you can use [SOPS](https://github.com/mozilla/sops) CLI to encrypt
Kubernetes secrets with OpenPGP, AWS KMS, GCP KMS and Azure Key Vault.

## Prerequisites

To follow this guide you'll need a Kubernetes cluster with the GitOps
toolkit controllers installed on it.
Please see the [get started guide](/flux/get-started/index.md)
or the [installation guide](/flux/installation/).

Install [gnupg](https://www.gnupg.org/) and [SOPS](https://github.com/mozilla/sops):

```sh
brew install gnupg sops
```

## Generate a GPG key

Generate a GPG/OpenPGP key with no passphrase (`%no-protection`):

```sh
export KEY_NAME="cluster0.yourdomain.com"
export KEY_COMMENT="flux secrets"

gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: ${KEY_COMMENT}
Name-Real: ${KEY_NAME}
EOF
```

The above configuration creates an rsa4096 key that does not expire.
For a full list of options to consider for your environment, see
[Unattended GPG key generation](https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html).

Retrieve the GPG key fingerprint (second row of the sec column):

```sh
gpg --list-secret-keys "${KEY_NAME}"

sec   rsa4096 2020-09-06 [SC]
      1F3D1CED2F865F5E59CA564553241F147E7C5FA4
```

Store the key fingerprint as an environment variable:

```sh
export KEY_FP=1F3D1CED2F865F5E59CA564553241F147E7C5FA4
```

Export the public and private keypair from your local GPG keyring and
create a Kubernetes secret named `sops-gpg` in the `flux-system` namespace:

```sh
gpg --export-secret-keys --armor "${KEY_FP}" |
kubectl create secret generic sops-gpg \
--namespace=flux-system \
--from-file=sops.asc=/dev/stdin
```

It's a good idea to back up this secret-key/K8s-Secret with a password manager or offline storage.
Also consider deleting the secret decryption key from your machine:

```sh
gpg --delete-secret-keys "${KEY_FP}"
```

## Configure in-cluster secrets decryption

Register the Git repository on your cluster:

```sh
flux create source git my-secrets \
--url=https://github.com/my-org/my-secrets \
--branch=main
```

Create a kustomization for reconciling the secrets on the cluster:

```sh
flux create kustomization my-secrets \
--source=my-secrets \
--path=./clusters/cluster0 \
--prune=true \
--interval=10m \
--decryption-provider=sops \
--decryption-secret=sops-gpg
```

Note that the `sops-gpg` can contain more than one key, SOPS will try to decrypt the
secrets by iterating over all the private keys until it finds one that works.

## Optional: Export the public key into the Git directory

Commit the public key to the repository so that team members who clone the repo can encrypt new files:

```sh
gpg --export --armor "${KEY_FP}" > ./clusters/cluster0/.sops.pub.asc
```

Check the file contents to ensure it's the public key before adding it to the repo and committing.

```sh
git add ./clusters/cluster0/.sops.pub.asc
git commit -am 'Share GPG public key for secrets generation'
```

Team members can then import this key when they pull the Git repository:

```sh
gpg --import ./clusters/cluster0/.sops.pub.asc
```

{{% alert color="info" %}}
The public key is sufficient for creating brand new files.
The secret key is required for decrypting and editing existing files because SOPS computes a MAC on all values.
When using solely the public key to add or remove a field, the whole file should be deleted and recreated.
{{% /alert %}}

## Configure the Git directory for encryption

Write a [SOPS config file](https://github.com/mozilla/sops#using-sops-yaml-conf-to-select-kms-pgp-for-new-files)
to the specific cluster or namespace directory used
to store encrypted objects with this particular GPG key's fingerprint.

```yaml
cat <<EOF > ./clusters/cluster0/.sops.yaml
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    pgp: ${KEY_FP}
EOF
```

This config applies recursively to all sub-directories.
Multiple directories can use separate SOPS configs.
Contributors using the `sops` CLI to create and encrypt files
won't have to worry about specifying the proper key for the target cluster or namespace.

`encrypted_regex` helps encrypt the `data` and `stringData` fields for Secrets.
You may wish to add other fields if you are encrypting other types of Objects.

{{% alert color="info" title="Hint" %}}
Note that you should encrypt only the `data` or `stringData` section. Encrypting the Kubernetes
secret metadata, kind or apiVersion is not supported by kustomize-controller.
{{% /alert %}}

## Encrypting secrets using OpenPGP

Generate a Kubernetes secret manifest with kubectl:

```sh
kubectl -n default create secret generic basic-auth \
--from-literal=user=admin \
--from-literal=password=change-me \
--dry-run=client \
-o yaml > basic-auth.yaml
```

Encrypt the secret with SOPS using your GPG key:

```sh
sops --encrypt --in-place basic-auth.yaml
```

You can now commit the encrypted secret to your Git repository.

{{% alert color="info" title="Hint" %}}
Note that you shouldn't apply the encrypted secrets onto the cluster with kubectl. SOPS encrypted secrets are designed to be consumed by kustomize-controller.
{{% /alert %}}

## Encrypting secrets using age

[age](https://github.com/FiloSottile/age) is a simple, modern alternative to OpenPGP. It's recommended to use age over OpenPGP, if possible.

Encrypting with age follows the same workflow than PGP.

Generate an age key with [age](https://age-encryption.org) using `age-keygen`:

```console
$ age-keygen -o age.agekey
Public key: age1helqcqsh9464r8chnwc2fzj8uv7vr5ntnsft0tn45v2xtz0hpfwq98cmsg
```

Create a secret with the age private key,
the key name must end with `.agekey` to be detected as an age key:

```sh
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```

Use `sops` and the age public key to encrypt a Kubernetes secret:

```sh
sops --age=age1helqcqsh9464r8chnwc2fzj8uv7vr5ntnsft0tn45v2xtz0hpfwq98cmsg \
--encrypt --encrypted-regex '^(data|stringData)$' --in-place basic-auth.yaml
```

And finally set the decryption secret in the Flux Kustomization to `sops-age`.

## Encrypting secrets using HashiCorp Vault

[HashiCorp Vault](https://www.vaultproject.io/docs/what-is-vault) is an identity-based secrets and encryption management system.

Encrypting with HashiCorp Vault follows the same workflow as PGP & Age.

Export the `VAULT_ADDR`  and `VAULT_TOKEN` environment variables to your shell,
then use `sops` to encrypt a Kubernetes Secret (see [HashiCorp Vault](https://www.vaultproject.io/docs/secrets/transit)
for more details on enabling the transit backend and [sops](https://github.com/mozilla/sops#encrypting-using-hashicorp-vault)).

Then use `sops` to encrypt a Kubernetes Secret:

```sh
export VAULT_ADDR=https://vault.example.com:8200
export VAULT_TOKEN=my-token
sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/my-encryption-key --encrypt \
--encrypted-regex '^(data|stringData)$' --in-place basic-auth.yaml
```

Create a secret the vault token,
the key name must be `sops.vault-token` to be detected as a vault token:

```sh
echo $VAULT_TOKEN |
kubectl create secret generic sops-hcvault \
--namespace=flux-system \
--from-file=sops.vault-token=/dev/stdin
```

And finally set the decryption secret in the Flux Kustomization to `sops-hcvault`.

## Encrypting secrets using various cloud providers

When using AWS/GCP KMS, you don't have to include the gpg `secretRef` under
`spec.provider` (you can skip the `--decryption-secret` flag when running `flux create kustomization`),
instead you'll have to bind an IAM Role with access to the KMS
keys to the `kustomize-controller` service account of the `flux-system` namespace for
kustomize-controller to be able to fetch keys from KMS.

#### AWS

Enabled the [IAM OIDC provider](https://eksctl.io/usage/iamserviceaccounts/) on your EKS cluster:

```sh
eksctl utils associate-iam-oidc-provider --cluster=<clusterName>
```

Create an IAM Role with access to AWS KMS e.g.:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:kms:eu-west-1:XXXXX209540:key/4f581f5b-7f78-45e9-a543-83a7022e8105"
        }
    ]
}
```

{{% alert color="info" title="Hint" %}}
The above policy represents the minimal permissions needed for the controller
to be able to decrypt secrets. Policies for users/clients who are meant to be encrypting and managing
secrets will additionally require the `kms:Encrypt`, `kms:ReEncrypt*` and `kms:GenerateDataKey*` actions.
{{% /alert %}}

Bind the IAM role to the `kustomize-controller` service account:

```sh
eksctl create iamserviceaccount \
--role-only \
--name=kustomize-controller \
--namespace=flux-system \
--attach-policy-arn=<policyARN> \
--cluster=<clusterName>
```

Annotate the kustomize-controller service account with the role ARN:

```sh
kubectl -n flux-system annotate serviceaccount kustomize-controller \
--field-manager=flux-client-side-apply \
eks.amazonaws.com/role-arn='arn:aws:iam::<ACCOUNT_ID>:role/<KMS-ROLE-NAME>'
```

Restart kustomize-controller for the binding to take effect:

```sh
kubectl -n flux-system rollout restart deployment/kustomize-controller
```

{{% alert color="info" title="Bootstrap" %}}
Note that when using `flux bootstrap` you can [set the annotation](/flux/installation/configuration/workload-identity/#aws-iam-roles-for-service-accounts) to take effect at install time.
{{% /alert %}}

#### Azure

[Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster#create-aks-cluster) has to be enabled on the cluster. These are the steps to setup the identity, patch kustomize-controller to authenticate with the federated identity setup with Azure key vault. 

Setup the identity: 

```sh
export RESOURCE_GROUP=<AKS-RESOURCE-GROUP>
export CLUSTER_NAME=<AKS-CLUSTER-NAME>
export IDENTITY_NAME="sops-akv-decryptor"
export FEDERATED_IDENTITY_NAME="sops-akv-decryptor-federated"

# Get the OIDC Issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n ${CLUSTER_NAME} -g ${RESOURCE_GROUP} --query "oidcIssuerProfile.issuerUrl" -otsv)"

# Create the managed identity
az identity create --name "${IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}"

# Get identity client ID
export USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group ${RESOURCE_GROUP} --name ${IDENTITY_NAME} --query 'clientId' -o tsv)"

# Federate the identity with the kustomize controller sa in flux-system ns
az identity federated-credential create \
--name "${FEDERATED_IDENTITY_NAME}" \
--identity-name "${IDENTITY_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--issuer "${AKS_OIDC_ISSUER}" \
--subject system:serviceaccount:flux-system:kustomize-controller \
--audience api://AzureADTokenExchange
```

Create the Azure Key-Vault and give the required permissions to the managed identity. The key id in the last step is used to encrypt secrets with sops client.


```sh
export VAULT_NAME="fluxcd-$(uuidgen | tr -d - | head -c 16)"
export KEY_NAME="sops-cluster0"
export LOCATION=<AZURE-REGION>

az keyvault create --name "${VAULT_NAME}" --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}"

az keyvault key create --name "${KEY_NAME}" \
  --vault-name "${VAULT_NAME}" \
  --protection software \
  --ops encrypt decrypt

az keyvault set-policy --name "${VAULT_NAME}" \
 --spn "${USER_ASSIGNED_CLIENT_ID}"
 --key-permissions decrypt

az keyvault key show --name "${KEY_NAME}" \
  --vault-name "${VAULT_NAME}" \
  --query key.kid

```

Setup kustomize-controller to use workload identity adding the following patches to the flux-system kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          azure.workload.identity/client-id: <AZURE CLIENT ID>
          azure.workload.identity/tenant-id: <AZURE TENANT ID>
    target:
      kind: ServiceAccount
      name: "(kustomize-controller)"
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: controller
        labels:
          azure.workload.identity/use: "true"
      spec:
        template:
          metadata:
            labels:
              azure.workload.identity/use: "true"    
    target:
      kind: Deployment
      name: "(kustomize-controller)"
```


At this point, kustomize-controller is now authorized to decrypt values in
SOPS encrypted files from your Sources via the related Key Vault.

See the SOPS guide to
[Encrypting Using Azure Key Vault](https://github.com/mozilla/sops#encrypting-using-azure-key-vault)
to get started committing encrypted files to your Git Repository or other Sources.

#### Google Cloud

[Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#before_you_begin) has to be enabled on the cluster and on the node pools.

{{% alert color="info" title="Terraform" %}} If you like to use terraform instead of gcloud, you will need the following resources from the `hashicorp/google` provider:

* create GCP service account: "google_service_account"
* add role KMS encrypter/decrypter: "google_project_iam_member"
* bind GCP SA to Flux kustomize-controller SA: "google_service_account_iam_binding" {{% /alert %}}

1. Create a [GCP service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#before-you-begin) with the role Cloud KMS CryptoKey Encrypter/Decrypter.

``` sh
gcloud iam service-accounts create <SERVICE_ACCOUNT_ID> \
    --description="DESCRIPTION" \
    --display-name="DISPLAY_NAME"
```

``` sh
gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:<SERVICE_ACCOUNT_ID>@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"
```

2. Create an IAM policy binding between the GCP service account and the kustomize-controller Kubernetes service account of the flux-system.

``` sh
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>.svc.id.goog[<K8S_NAMESPACE>/<KSA_NAME>]" \
  SERVICE_ACCOUNT_ID@PROJECT_ID.iam.gserviceaccount.com
```

For a GCP project named `total-mayhem-123456` with a configured GCP service account `flux-gcp` and assuming that Flux runs in the (default) namespace `flux-system`, this would translate to the following:

``` sh
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:total-mayhem-123456.svc.id.goog[flux-system/kustomize-controller]" \
  flux-gcp@total-mayhem-123456.iam.gserviceaccount.com
```

3. [Customize your Flux Manifests](/flux/installation/) and patch the kustomize-controller service account with the proper annotation so that Workload Identity knows the relationship between the gcp service account and the k8s service account.

``` yaml
### add this patch to annotate service account if you are using Workload identity
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: kustomize-controller
        namespace: flux-system
        annotations:
          iam.gke.io/gcp-service-account: <SERVICE_ACCOUNT_ID>@<PROJECT_ID>.iam.gserviceaccount.com
    target:
      kind: ServiceAccount
      name: kustomize-controller
```

If you didn't bootstrap Flux, you can use this instead

``` sh
kubectl annotate serviceaccount kustomize-controller \
--field-manager=flux-client-side-apply \
--namespace flux-system \
iam.gke.io/gcp-service-account=<SERVICE_ACCOUNT_ID>@<PROJECT_ID>.iam.gserviceaccount.com
```

{{% alert color="info" title="Bootstrap" %}}
Note that when using `flux bootstrap` you can [set the annotation](/flux/installation/configuration/workload-identity/#gcp-workload-identity) to take effect at install time.
{{% /alert %}}

## GitOps workflow

A cluster admin should create the Kubernetes secret with the PGP keys on each cluster and
add the GitRepository/Kustomization manifests to the fleet repository.

Git repository manifest:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-secrets
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/my-org/my-secrets
```

Kustomization manifest:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-secrets
  namespace: flux-system
spec:
  interval: 10m0s
  sourceRef:
    kind: GitRepository
    name: my-secrets
  path: ./
  prune: true
  decryption:
    provider: sops
    secretRef:
      name: sops-gpg
```

{{% alert color="info" title="Hint" %}}
You can generate the above manifests using `flux create <kind> --export > manifest.yaml`.
{{% /alert %}}

Assuming a team member wants to deploy an application that needs to connect
to a database using a username and password, they'll be doing the following:

* create a Kubernetes Secret manifest locally with the db credentials e.g. `db-auth.yaml`
* encrypt the secret `data` field with sops
* create a Kubernetes Deployment manifest for the app e.g. `app-deployment.yaml`
* add the Secret to the Deployment manifest as a [volume mount or env var](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets)
* commit the manifests `db-auth.yaml` and `app-deployment.yaml` to a Git repository that's being synced by the GitOps toolkit controllers

Once the manifests have been pushed to the Git repository, the following happens:

* source-controller pulls the changes from Git
* kustomize-controller loads the GPG keys from the `sops-pgp` secret
* kustomize-controller decrypts the Kubernetes secrets with SOPS and applies them on the cluster
* kubelet creates the pods and mounts the secret as a volume or env variable inside the app container

## SOPS encrypted_regex conflict

{{% alert color="warning" title="Security notice" %}}
The below example is injecting secret data into environment variable key-value pairs in the Pod spec, which is a bad security practice.
It should be taken as an explanation of Flux's behavior related to handling merging of secret data, not a security recommendation.
{{% /alert %}}

If your resource is encrypted it will be decrypted right before apply, but it may happen, that
your patches will bring fields that match SOPS' encrypted_regex expression and SOPS will fail
during the decryption. Let's say we have a simple resource.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  containers:
    - name: main
      image: nginx:stable-alpine
      env:
        - name: ENC[AES256_GCM,data:...
          value: ENC[AES256_GCM,data:...
      resources:
        limits:
          memory: 50Mi
          cpu: 50m
sops:
  ...
  encrypted_regex: ^env$ # There it is
  ...
```

This Pod has every env list encrypted since we have `encrypted_regex` set during SOPS encryption.
But next we have a patch like this.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  containers:
    - name: patched
      image: nginx:stable-alpine
      env:
        - name: MainEnvValueIsEncrypted
          value: but this one is not
```

And as a result you will have.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  containers:
    - name: main
      image: nginx:stable-alpine
      env:
        - name: ENC[AES256_GCM,data:...
          value: ENC[AES256_GCM,data:...
      resources:
        limits:
          memory: 50Mi
          cpu: 50m
    - name: patched
      image: nginx:stable-alpine
      env:
        - name: MainEnvValueIsEncrypted
          value: but this one is not
sops:
  ...
  encrypted_regex: ^env$ # There it is
  ...
```

At this point, Flux will call SOPS to decrypt the file and SOPS will try to decrypt
all `env` keys, but container `patched` has this list in a plain text. SOPS will fail here.

{{% alert color="info" title="Hint" %}}
Move all your secrets to patches and your resource will not require a decryption at the end, since patches are decrypted before.
{{% /alert %}}

## SOPS Encrypted Kustomize patches

SOPS-encrypted data can be stored as [Kustomize `patches`](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) as long as they're in separate files, not inlined in `kustomization.yaml`. The kustomize-controller decrypts these before executing kustomization pipeline, allowing for adding secret data to resources or merging Secrets. For example:

```yaml
# patch1.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
stringData:
  secretConfig: "my-secret-configuration"
```

```yaml
# patch2.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
stringData:
  secretToken: "my-secret-token"
```

```yaml
# base.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
  annotations:
    kubernetes.io/description: "This is a secret that is patched together of multiple objects."
stringData: {}
```

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - base.yaml
patches:
  - path: patch1.yaml
  - path: patch2.yaml
```

```sh
sops -e --input-type=yaml patch1.yaml 
sops -e --input-type=yaml patch2.yaml
```

After kustomize-controller does the reconciliation of `kustomization.yaml`, the following secret will be generated in the cluster:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret
  annotations:
    kubernetes.io/description: "This is a secret that is patched together of multiple objects."
stringData:
  secretToken: "my-secret-token"
  secretConfig: "my-secret-configuration"
```
