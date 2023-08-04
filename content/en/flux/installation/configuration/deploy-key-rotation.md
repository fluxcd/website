---
title: "Flux deploy key rotation"
linkTitle: "Deploy key rotation"
description: "How to rotate the deploy key generated at bootstrap"
weight: 19
---

There are several reasons you may want to rotate the deploy key:

- The token used to generate the key has expired.
- The key has been compromised.
- You want to change the scope of the key, e.g. to allow write access using the `--read-write-key` flag to `flux bootstrap`.

While you can run `flux bootstrap` repeatedly, be aware that the `flux-system` Kubernetes Secret is never overwritten.
You need to manually rotate the key as described here.

To rotate the SSH key generated at bootstrap, first delete the secret from the cluster with:

```sh
kubectl -n flux-system delete secret flux-system
```

Then you have two alternatives to generate a new key:

1. Generate a new secret with

   ```sh
   flux create secret git flux-system \
     --url=ssh://git@<host>/<org>/<repository>
   ```
   The above command will print the SSH public key, once you set it as the deploy key,
   Flux will resume all operations.
2. Run `flux bootstrap ...` again. This will generate a new key pair and,
   depending on which Git provider you use, print the SSH public key that you then
   set as deploy key or automatically set the deploy key (e.g. with GitHub).
