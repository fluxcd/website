---
title: Using Flux on GCP With Source Repository
linkTitle: Google Cloud Source Repositories
description: "How to bootstrap Flux on GCP GKE with Cloud Source repositories."
weight: 10
---

### Cluster Creation

To create a cluster with Google Cloud you can use the `gcloud` cli or the Google Cloud Console.

The following command creates a cluster with the default configuration.

```sh
gcloud containers create sample-cluster
```

For more details on how to create a GKE cluster with `gcloud`,
please see [the Cloud SDK Documentation](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)

### Source Repository Creation

Create a Cloud Source Repository that will hold your Flux installation manifests and other Kubernetes resources.
Like the cluster, it can be created with the CLI or the console.

### Flux Installation

Download the [Flux CLI](../installation.md#install-the-flux-cli) and bootstrap Flux with:

```sh
flux bootstrap git \
--url=ssh://<user>s@source.developers.google.com:2022/p/<project-name>/r/<repo-name> \
--branch=master \
--path=clusters/my-cluster
```

The above command will prompt you to add a deploy key to your repository, but Cloud Source Repository
does not support repository or org-specific deploy keys. You may add the deploy key to a user's
personal SSH keys, but take note that revoking the user's access to the repository will
also revoke Flux's access. The better alternative is to create a dedicated user for Flux.

You can also use a SSH key that was already added to Cloud Source Repository
by adding the `--private-key-file` and `--password` flags.

### Flux Upgrade

To upgrade Flux, first you need to download the new CLI binary
from [GitHub release](../installation.md#install-the-flux-cli).

Flux components can be upgraded by running the `bootstrap` command again with the same arguments as before:

```sh
flux bootstrap git \
--url=ssh://<user>s@source.developers.google.com:2022/p/<project-name>/r/<repo-name> \
--branch=master \
--path=clusters/my-cluster
```

To upgrade Flux in a GitOps manner, you can generate the components manifests with the `install` command
and commit the changes to your Git repository:

```sh
flux install --export > clusters/my-cluster/flux-system/gotk-components.yaml
git add -A
git commit -m "Update $(flux -v)"
git push
```

Once Flux detects the changes in Git, it will upgrade itself.

### Secrets Management with SOPS and GCP KMS

You would need to create GCP KMS key and have
[workload identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) enabled on the GKE cluster. 
Create an IAM service account that has `Cloud KMS CryptoKey Decrypter` role and allow the kustomize-controller
service account to impersonate this service account by adding an IAM policy binding between it and the IAM service account.

```sh
gcloud iam service-accounts add-iam-policy-binding <iam-service-account>@<project-name>.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:<project-name>.svc.id.goog[flux-system/kustomize-controller]"
```

Patch the kustomize-controller with the
`iam.gke.io/gcp-service-account=<iam-service-account>@<project-name>.iam.gserviceaccount.com`
annotation so that it can access GCP KMS.
You can start committing your encrypted files to Git with the proper GCP KMS configuration.

See the [Mozilla SOPS AWS Guide](../guides/mozilla-sops.md#google-cloud) for further detail.

### Image Updates with Google Container Registry

You will need to create an GCR registry. Most new GKE cluster by default have access to
Google Container Registry in the same project.
But if you have enabled Workload Identity on your cluster,
you would need to create an IAM service account that has access to GCR.

You may need to update your Flux install to include additional components:

```sh
flux bootstrap git \
--url=ssh://<user>s@source.developers.google.com:2022/p/<project-name>/r/<repo-name> \
--branch=master \
--path=clusters/my-cluster
--components-extra="image-reflector-controller,image-automation-controller"
```

Follow the [Image Update Automation Guide](../guides/image-update.md) and see the
[GCP specific Image Automation Contollers documentation](../components/image/imagerepositories/#gcp)
for more details on how to configure image update automation for GKE.
