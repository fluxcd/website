---
title: Using Flux on OpenShift
linkTitle: OpenShift
---

## OpenShift Setup

Steps described in this document has been tested on OpenShift 4.6 only. 
You require cluster-admin privileged to install Flux on OpenShift. This means that it currently is not possiple to install Flux on the OpenShift Developer Sandbox.

### CodeReady Containers
An easy way to provision OpenShift is to use CodeReady Containers (CRC) for OpenShift, which could be obtained from [here](https://developers.redhat.com/products/codeready-containers/overview). With this setup, you require a physical Linux box. An OpenShift cluster will run inside a VM installed by CRC. 

{{% alert %}}
Despite being a single node, the cluster will consume a large amount of both CPU and memory resources. Your desktop / laptop must have at least 8 CPU cores with 32 GB of RAM as it is recommened to allocate at least 4 CPU cores and 18 GB of RAM for the cluster to have a good experience.
{{% /alert %}}

```sh
# Setup the OpenShift configuration
# You require to paste a pull secret here
crc setup

# Start the cluster with 18 GB of RAM
crc start -c 4 -m 18432
```

After the cluster up and running, there will be a message tell us how to login.
Please make sure that you use `kubeadmin` user to login before installing Flux.

```sh
# Prepare environment setup for the OC command
eval $(crc oc-env)

# Login 
oc login -u kubeadmin -p <your password> https://api.crc.testing:6443
```

### Security Context Constraints

Before installing Flux, you require to set the **privileged** security context constraint for the following controller in the `flux-system` namespace.

```sh
NS="flux-system"
oc adm policy add-scc-to-user privileged system:serviceaccount:$NS:source-controller
oc adm policy add-scc-to-user privileged system:serviceaccount:$NS:kustomize-controller
oc adm policy add-scc-to-user privileged system:serviceaccount:$NS:image-automation-controller
oc adm policy add-scc-to-user privileged system:serviceaccount:$NS:image-reflector-controller
```

## Flux Installation with CLI

The best way to install Flux on OpenShift currently is to use `flux bootstrap` command. Assuming that you are a GitHub user, you could start by preparing your GitHub credentials.

```sh
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
```

Then simply bootstrap Flux.

```sh
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=openshift-gitops \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```

and enjoy your GitOps on OpenShift.

## Flux Upgrade

Upgrading Flux on OpenShift is very simple and straightforward. Please just make sure that you already logged in as `kubeadmin` user. Assuming you are a Homebrew user, you could upgrade Flux CLI using the following command.

```sh
# Upgrade Flux
brew upgrade fluxcd/tap/flux

# Check Flux version
flux -v

# Login as kubeadmin
oc login -u kubeadmin -p <your password> https://api.crc.testing:6443
```

After you obtained the Flux version you wanted, simply re-run the above `flux bootstrap` command from the prevous section, and all of your Flux component will be upgraded.

```sh
# Re-running the bootstrap command to upgrade
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=openshift-gitops \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal
```
