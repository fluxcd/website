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

See the SOPS guide to [Encrypting Using AWS KMS](https://github.com/getsops/sops#usage).

See the AWS integrations [docs](/flux/integrations/aws.md) for details on how to set up
SOPS authentication for AWS KMS in kustomize-controller.

#### Azure

See the SOPS guide to [Encrypting Using Azure Key Vault](https://github.com/getsops/sops#encrypting-using-azure-key-vault).

See the Azure integrations [docs](/flux/integrations/azure.md) for details on how to set up
SOPS authentication for Azure Key Vault in kustomize-controller.

#### GCP

See the SOPS guide to [Encrypting Using GCP KMS](https://github.com/getsops/sops#encrypting-using-gcp-kms).

See the GCP integrations [docs](/flux/integrations/gcp.md) for details on how to set up
SOPS authentication for GCP KMS in kustomize-controller.

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
