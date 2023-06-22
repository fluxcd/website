---
title: Using Flux on OpenShift
linkTitle: OpenShift
description: "How to bootstrap Flux on OpenShift."
weight: 20
---

## OpenShift Setup

Steps described in this document have been tested on OpenShift 4.6, 4.7 and 4.8.
You require cluster-admin privileges to install Flux on OpenShift.
This means that it currently is not possible to install Flux on the OpenShift Developer Sandbox.

### CodeReady Containers

An easy way to provision OpenShift is to use CodeReady Containers (CRC) for OpenShift,
which could be obtained from [here](https://developers.redhat.com/products/codeready-containers/overview).
With this setup, you require a physical Linux box. An OpenShift cluster will run inside a VM installed by CRC. 

{{% alert color="info" title="Resource Usage" %}}
Please note that your desktop / laptop should have at least 8 CPU cores with 32 GB of RAM as it is recommended to allocate
at least 4 CPU cores and 18 GB of RAM for the cluster to have a good experience.
{{% /alert %}}

```sh
# Setup the OpenShift configuration
# You need to paste a pull secret here
crc setup

# Start the cluster with 18 GB of RAM
crc start -c 4 -m 18432
```

After the cluster is up and running, there will be a message tell us how to login.
Please make sure that you use `kubeadmin` user to login before installing Flux.

```sh
# Prepare environment setup for the OC command
eval $(crc oc-env)

# Login 
oc login -u kubeadmin -p <your password> https://api.crc.testing:6443
```

## Flux Installation with CLI

The best way to install Flux on OpenShift currently is to use the `flux bootstrap` command.
This command works with GitHub, GitLab as well as generic Git provider.

Before installing Flux with CLI, you need to set the **nonroot** SCC for all controllers in the `flux-system` namespace, like this:

```sh
NS="flux-system"
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:kustomize-controller
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:helm-controller
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:source-controller
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:notification-controller
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:image-automation-controller
oc adm policy add-scc-to-user nonroot system:serviceaccount:${NS}:image-reflector-controller
```

Also, you have to patch your Kustomization to remove the SecComp Profile and enforce `runUserAs` to the same UID provided by the images to prevent OpenShift to alter the user expected by our controllers, before bootstrapping by.

1. You’ll need to create a Git repository and clone it locally.

2. Create the file structure required by bootstrap using the following command:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

3. Add the following YAML snippet and its patches section to kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  # Remove seccompProfile from the flux Deployments when running on OpenShift
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            containers:
              - name: manager
                securityContext:
                  runAsUser: 65534
                  seccompProfile:
                    $patch: delete
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
  # OpenShift will overwrite these Namespace labels
  # Remove them from the flux definition and leave them to openshift.
  - patch: |-
      - op: remove
        path: /metadata/labels/pod-security.kubernetes.io~1warn
      - op: remove
        path: /metadata/labels/pod-security.kubernetes.io~1warn-version
    target:
      kind: Namespace
      labelSelector: app.kubernetes.io/part-of=flux
```

4. Commit and push the changes to main branch:

```sh
git add -A && git commit -m "init flux for openshift" && git push
```

Then you can continue with the Flux bootstrap process. Assuming that you are a GitHub user, you could start by preparing your GitHub credentials.

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
```

And run the Flux bootstrap command.

```sh
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=openshift-gitops \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

Please refer to the command's documentations [here](../installation/_index.md#bootstrap) in details.

## Flux Upgrade

Upgrading Flux on OpenShift is very simple and straightforward.
Please just make sure that you are already logged in as `kubeadmin` user.
Assuming you are a Homebrew user, you could upgrade Flux CLI using the following command.

```sh
# Upgrade Flux
brew upgrade fluxcd/tap/flux

# Check Flux version
flux -v

# Login as kubeadmin
oc login -u kubeadmin -p <your password> https://api.crc.testing:6443
```

After you obtained the Flux version you wanted, simply re-run the above `flux bootstrap`
command from the previous section, and all of your Flux component will be upgraded.

```sh
# Re-running the bootstrap command to upgrade
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=openshift-gitops \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

Please see also the [upgrade](../installation/_index.md#upgrade)
and the [bootstrap upgrade](../installation/_index.md#bootstrap-upgrade) documentations for details.

## Flux Installation via OperatorHub

Flux is available on OperatorHub and Red Hat OpenShift Community Operators, which means that you can install Flux directly from the Red Hat OperatorHub user interface.

On the OpenShift UI, you go to "Operators -> OperatorHub" menu, search for "Flux", click the Flux Operator, then click the "Install" button.

Here's the link to [Flux on OperatorHub](https://operatorhub.io/operator/flux).
