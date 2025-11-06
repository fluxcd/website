---
title: "Setup GPG commit verification"
linkTitle: "Setup GPG commit verification"
description: "Configure GPG commit verification to add another layer of security in case of compromised GitOps repository"
weight: 100
---

You may want to add another layer of security in case your GitOps repository is compromised.  
With commit signature verification, commits must be [signed](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work) using an authorized GPG key to be applied to the cluster.

## Prerequisites

To follow this guide you'll need a Kubernetes cluster with the GitOps 
toolkit controllers installed on it.
Please see the [get started guide](../get-started/index.md)
or the [installation guide](../installation/).

## Import your GPG public keys as Secret

In order to verify commit signatures, the source controller needs to have GPG **public** keys.

Create a `flux-gpg-pubkeys` secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: flux-gpg-pubkeys
  namespace: flux-system
data:
  my_key.asc: <YOUR KEY IN BASE64>
```
Note: You can add multiple keys

Your GPG key may be exported as one-line base64 string using:

```sh
gpg --armor --export <KEY_ID> | base64 -w 0
```

## Configure GOTK to verify commit signature

You have to [customize flux manifests](../installation/#customize-flux-manifests) to enable signature verification.

Create a patch as `gpg-commit-verification.yaml` in `flux-system` directory:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  verify:
    mode: head
    secretRef:
      name: flux-gpg-pubkeys
```

Include this patch using `patchesStrategicMerge` in `kustomization.yaml`:

```yaml
patchesStrategicMerge:
- gpg-commit-verification.yaml
```

Commit and push your changes.

Future commits must now be signed.  
If a commit is not signed, it will not be applied to the cluster (an error will be showed in source controller logs)
