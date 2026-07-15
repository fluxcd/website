---
author: Matheus Pimenta, Fabian Kammel
date: 2026-07-27 11:00:00+00:00
title: "Flux and OpenBao: Secrets and Signatures"
description: "In this post we explore two Flux integrations with OpenBao: SOPS decryption through workload identity and sovereign OCI artifact signing with Cosign."
url: /blog/2026/07/flux-openbao-secrets-signatures/
tags: [integrations]
resources:
  - src: "**.{png,jpg}"
    title: "Image #:counter"
---

OpenBao can hold the keys behind two security-sensitive parts of a GitOps pipeline. Flux can use its transit engine to decrypt SOPS secrets without a stored token, while Cosign can use it to sign OCI artifacts that Flux verifies before reconciliation.

TODO: REPLACE FEATURED IMAGE!

![](featured-image.png)

## SOPS: GitOps secrets without a static token

Keeping encrypted Secrets in Git solves most of the secret-distribution problem. For a SOPS encryption key living in OpenBao's transit engine, before 2.9 Flux still needed a static `VAULT_TOKEN` to ask OpenBao for decryption: one secret that had to exist before GitOps could take charge of managing secrets. Starting with Flux 2.9, that token is optional: kustomize-controller can use ServiceAccount tokens to authenticate to OpenBao, so Flux can manage secrets without any pre-existing secret.

### Step 1: Encrypt a Secret with OpenBao

After authenticating to OpenBao, a developer or CI job asks SOPS to encrypt a regular Kubernetes Secret using an OpenBao transit key:

```shell
sops encrypt \
  --hc-vault-transit https://openbao.example.com:8200/v1/transit/keys/sops \
  --encrypted-regex '^(data|stringData)$' \
  secret.yaml > secret.enc.yaml
```

The resulting `secret.enc.yaml` is ready for Git. It looks like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database
  namespace: apps
type: Opaque
stringData:
  username: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
  password: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
sops:
  hc_vault:
    - vault_address: https://openbao.example.com:8200
      engine_path: transit
      key_name: sops
      created_at: "2026-07-14T12:00:00Z"
      enc: vault:v1:...
  encrypted_regex: ^(data|stringData)$
  mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
```

SOPS replaces the plaintext content with ciphertext and adds a `sops.hc_vault` metadata field routing the encryption to OpenBao.

### Step 2: Configure kustomize-controller to use workload identity for OpenBao

When Flux reconciles files like the one above, it asks OpenBao to decrypt the content. Before Flux 2.9, that request depended on the static `VAULT_TOKEN`. Flux 2.9 replaces that token with an opt-in workload identity path. Operators give kustomize-controller an allowlist of OpenBao instances and their JWT-backed login endpoints. This is done by creating a ConfigMap in the `flux-system` namespace and pointing kustomize-controller to its name through the flag `--sops-vault-configmap`. The ConfigMap looks like this:

```yaml
data:
  config.yaml: |
    instances:
      - address: https://openbao.example.com:8200
        loginPath: auth/kubernetes/login
```

With that in place, the OpenBao address in the SOPS metadata selects an entry from this list. kustomize-controller requests a Kubernetes ServiceAccount token with that address as its audience, then presents it at the configured login path under a role derived from the ServiceAccount as `{namespace}_{name}`. OpenBao returns a short-lived token, which Flux then uses to call OpenBao's transit engine to decrypt the Secret.

### Step 3: Use a dedicated ServiceAccount for decryption

By default, the exchange described above uses kustomize-controller's own ServiceAccount. A Flux Kustomization can instead select a dedicated ServiceAccount:

```yaml
spec:
  decryption:
    provider: sops
    serviceAccountName: sops
```

Per-Kustomization decryption ServiceAccounts require the `ObjectLevelWorkloadIdentity` feature gate to be enabled in kustomize-controller.

OpenBao's [Kubernetes auth method](https://openbao.org/api-docs/auth/kubernetes/) and [JWT/OIDC auth method](https://openbao.org/api-docs/auth/jwt/) documentation cover the OpenBao-side setup.

## Cosign: Sovereign Software Signatures

Flux can verify the signature of an OCI artifact before it reconciles it, using [Cosign](https://docs.sigstore.dev/). That verification is deliberately **backend-agnostic**: Flux takes a public key, checks a signature, and forms no opinion about how or where the artifact was signed. With a static key, it never reaches out to Fulcio or Rekor.

That property is more useful than it first appears. It means you can build a signing chain that depends on nothing outside infrastructure you run - no public cloud KMS holding your key, no public Sigstore transparency log in the path. This post walks through one such chain: [OpenBao](https://openbao.org/) holds the signing key, Cosign signs the artifact, and Flux verifies it. Every step stays on your side of the network boundary, which matters for regulated environments, data-sovereignty requirements, and anyone who would rather not rent a link in their trust chain from a service they don't control.

The full, reproducible setup lives at [openbao-flux-demo](https://github.com/controlplaneio-openbao/openbao-flux-demo). What follows are the pieces that matter.

```text
OpenBao transit engine   →   Cosign   →   GHCR (artifact + signature)   →   Flux
holds the signing key        signs        stores signature                  verifies
```

### The signing key stays in OpenBao

OpenBao's transit secrets engine is a cryptography-as-a-service backend: it holds key material and performs sign and verify operations on request. Cosign has native support for it through the `openbao://` KMS URI, so generating the key is a single command - and the private half is created inside OpenBao and never written to disk:

```shell
cosign generate-key-pair --kms openbao://control-plane-demo
```

Only `cosign.pub` lands on your filesystem. That public key is the sole piece of the chain Flux needs to verify signatures later.

The demo runs OpenBao in dev mode with a root token, which is fine for a throwaway cluster and nothing else. In production you would sign with a token scoped to just this key - read the public key and sign, nothing more:

```hcl
path "transit/keys/control-plane-demo" {
  capabilities = ["read"]
}

path "transit/sign/control-plane-demo" {
  capabilities = ["update"]
}
```

### Sign by digest, without the transparency log

Package the manifests as an OCI artifact and push them to the registry with the Flux CLI:

```shell
flux push artifact oci://ghcr.io/controlplaneio-openbao/openbao-flux-demo-workload:latest \
  --path=./workload \
  --source="https://github.com/controlplaneio-openbao/openbao-flux-demo" \
  --revision="main@sha1:$(git rev-parse HEAD)"
```

Then sign the pushed artifact by its digest. Passing `--tlog-upload=false` keeps the signature off the public Rekor log, so the signing event itself never becomes a public record:

```shell
cosign sign --key openbao://control-plane-demo --tlog-upload=false \
  ghcr.io/controlplaneio-openbao/openbao-flux-demo-workload@sha256:...
```

OpenBao performs the signing operation, and the signature is stored in the registry alongside the artifact. One thing to watch: Cosign authenticates to the registry separately from `flux push artifact --creds` - the two don't share credentials, so Cosign needs its own `cosign login`.

### Bootstrapping Flux

Flux is installed by the [Flux Operator](https://fluxoperator.dev/) from a `FluxInstance`, which also points it at the repository path holding the verification resources. The repository is public, so Flux clones it anonymously - no pull secret needed:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.x"
    registry: "ghcr.io/fluxcd"
    artifact: "oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes
  sync:
    kind: GitRepository
    provider: generic
    url: "https://github.com/controlplaneio-openbao/openbao-flux-demo.git"
    ref: "refs/heads/main"
    path: "clusters/demo"
```

### Verifying the artifact

Create a Secret holding the Cosign public key, then reference it from an `OCIRepository`'s `.spec.verify`. The public key is not sensitive, so the demo creates the Secret directly; in production you would manage it declaratively with SOPS or sealed-secrets:

```shell
kubectl -n flux-system create secret generic cosign-public-key \
  --from-file=cosign.pub=cosign.pub
```

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: demo-workload
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/controlplaneio-openbao/openbao-flux-demo-workload
  ref:
    tag: latest
  verify:
    provider: cosign
    secretRef:
      name: cosign-public-key
```

When the signature checks out, Flux records it on the source and only then applies the manifests:

```text
SourceVerified=True (Succeeded): verified signature of revision latest@sha256:…
```

No part of that verification reached outside the cluster.

### Static keys or keyless

Flux supports both Cosign modes. Omit `.verify.secretRef` and Flux switches to keyless verification, matching OIDC identities against Fulcio certificates and the Rekor log. That is the right choice when short-lived identities and a public, auditable signing record are what you want, and reliance on public Sigstore infrastructure is acceptable.

This demo takes the other path on purpose. The goal is a chain with no public dependencies, so a static key held in OpenBao is the natural fit: you own key custody and rotation, and nothing in the flow calls out to a service you don't run. Neither mode is universally correct - they encode different trade-offs, and Flux lets you choose per source.

### Confirm that it blocks

A verification step is only worth having once you have watched it reject something. The demo includes a tamper test: it pushes an unsigned artifact to a separate tag and points a throwaway `OCIRepository` at it. Flux refuses to verify it, and the manifests never reach the cluster:

```text
SourceVerified=False
```

Worth running once - a rejected unsigned artifact is more reassuring than an accepted signed one.

### Try it

The repository wraps the whole flow in `make` targets - OpenBao, key generation, push, sign, Flux bootstrap, verify, and the tamper test - so you can reproduce it end to end on a throwaway cluster:

```shell
git clone https://github.com/controlplaneio-openbao/openbao-flux-demo
cd openbao-flux-demo
make prereqs
```

From there the README walks through each step. If you want to push further toward a fully self-hosted trust chain, a self-hosted Rekor instance is the logical next piece: static-key signing gives you self-custody of the key, and a private transparency log would add an auditable signing history without depending on the public ledger.

For more on the moving parts, see the [OCIRepository verification docs](https://fluxcd.io/flux/components/source/ocirepositories/#verification), the [Flux Operator](https://fluxoperator.dev/) documentation, OpenBao's [transit engine](https://openbao.org/docs/secrets/transit/), and Cosign's [KMS support](https://docs.sigstore.dev/cosign/key_management/overview/).

## References

- [Flux Kustomization decryption with OpenBao via workload identity](https://fluxcd.io/flux/components/kustomize/kustomizations/#openbaovault-kubernetes-auth)
- [OpenBao Kubernetes auth method API docs](https://openbao.org/api-docs/auth/kubernetes/)
- [OpenBao JWT/OIDC auth method API docs](https://openbao.org/api-docs/auth/jwt/)
- [Flux OCIRepository verification with public keys](https://fluxcd.io/flux/components/source/ocirepositories/#public-keys-verification)
