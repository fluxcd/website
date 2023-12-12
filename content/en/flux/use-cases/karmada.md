---
title: Karmada + Flux
linkTitle: Karmada + Flux
description: "How to use Karmada and Flux for distribution and management of multi-cluster Flux Helm releases."
weight: 20
---

{{% alert color="warning" title="Disclaimer" %}}
Note that this guide is not for doing GitOps, but for managing Helm releases for applications among multiple clusters.

Also note that this guide needs review in consideration of Flux v2.0.0, and likely needs to be refreshed.

Expect this doc to either be archived soon, or to receive some overhaul.
{{% /alert %}}

## Background

[Karmada](https://github.com/karmada-io/karmada) is a Kubernetes management system that enables you to run your cloud-native applications across multiple Kubernetes clusters and clouds, with no changes to your applications. 
By speaking Kubernetes-native APIs and providing advanced scheduling capabilities, Karmada enables truly open, multi-cloud Kubernetes.
With Karmada's centralized multi-cloud management, users can easily distribute and manage Helm releases in multiple clusters based on powerful Flux APIs.

## Karmada Setup

Steps described in this document have been tested on Karmada 1.0, 1.1 and 1.2.
To start up Karmada, you can refer to [here](https://github.com/karmada-io/karmada/blob/master/docs/installation/installation.md).
If you just want to try Karmada, we recommend building a development environment by ```hack/local-up-karmada.sh```.

```sh
git clone https://github.com/karmada-io/karmada
cd karmada
hack/local-up-karmada.sh
```

After that, you will start a Kubernetes cluster by kind to run the Karmada control plane and create member clusters managed by Karmada.

```sh
kubectl get clusters --kubeconfig ~/.kube/karmada.config
```

You can use the command above to check registered clusters, and you will get similar output as follows:

```
NAME      VERSION   MODE   READY   AGE
member1   v1.23.4   Push   True    7m38s
member2   v1.23.4   Push   True    7m35s
member3   v1.23.4   Pull   True    7m27s
```

### Flux Installation 

In Karmada control plane, you need to install Flux crds but do not need controllers to reconcile them. They are treated as resource templates, not specific resource instances. 
Based on work API [here](https://github.com/kubernetes-sigs/work-api), they will be encapsulated as a work object deliverd to member clusters and reconciled by Flux controllers in member clusters finally.

```sh
kubectl apply -k github.com/fluxcd/flux2/manifests/crds?ref=main --kubeconfig ~/.kube/karmada.config
```

For testing purposes, we'll install Flux on member clusters without storing its manifests in a Git repository:

```sh
flux install --kubeconfig ~/.kube/members.config --context member1
flux install --kubeconfig ~/.kube/members.config --context member2
```

Please refer to the documentations [here](/flux/installation/) for more ways to set up Flux in details.

{{% alert color="info" title="Tip" %}}
If you want to manage Helm releases across your fleet of clusters, Flux must be installed on each cluster.
{{% /alert %}}

## Helm release propagation

If you want to propagate Helm releases for your apps to member clusters, you can refer to the guide below.

1. Define a Flux `HelmRepository` and a `HelmRelease` manifest in Karmada Control plane. They will serve as resource templates. 

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: podinfo
spec:
  interval: 1m
  url: https://stefanprodan.github.io/podinfo  
---
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: podinfo
spec:
  interval: 5m
  chart:
    spec:
      chart: podinfo
      version: 5.0.3
      sourceRef:
        kind: HelmRepository
        name: podinfo
```

2. Define a Karmada `PropagationPolicy` that will propagate them to member clusters:

```yaml
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: helm-repo
spec:
  resourceSelectors:
    - apiVersion: source.toolkit.fluxcd.io/v1beta2
      kind: HelmRepository
      name: podinfo
  placement:
    clusterAffinity:
      clusterNames:
        - member1
        - member2
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: helm-release
spec:
  resourceSelectors:
    - apiVersion: helm.toolkit.fluxcd.io/v2beta2
      kind: HelmRelease
      name: podinfo
  placement:
    clusterAffinity:
      clusterNames:
        - member1
        - member2
```

The above configuration is for propagating the Flux objects to member1 and member2 clusters.

3. Apply those manifests to the Karmada-apiserver:

```sh
kubectl apply -f ../helm/ --kubeconfig ~/.kube/karmada.config
```

The output is similar to:

```
helmrelease.helm.toolkit.fluxcd.io/podinfo created
helmrepository.source.toolkit.fluxcd.io/podinfo created
propagationpolicy.policy.karmada.io/helm-release created
propagationpolicy.policy.karmada.io/helm-repo created
```

4. Switch to the distributed cluster and verify:

```sh
helm --kubeconfig ~/.kube/members.config --kube-context member1 list
```

The output is similar to:

```
NAME   	NAMESPACE	REVISION	UPDATED                               	STATUS  	CHART        	APP VERSION
podinfo	default  	1       	2022-05-27 01:44:35.24229175 +0000 UTC	deployed	podinfo-5.0.3	5.0.3
```

Based on Karmada's propagation policy, you can schedule Helm releases to your desired cluster flexibly, just like Kubernetes scheduling Pods to the desired node.

## Customize the Helm release for specific clusters

The example above shows how to distribute the same Helm release to multiple clusters in Karmada. Besides, you can use Karmada's OverridePolicy to customize applications for specific clusters.
For example, If you just want to change replicas in member1, you can refer to the overridePolicy below.

1. Define a Karmada `OverridePolicy`:

```yaml
apiVersion: policy.karmada.io/v1alpha1
kind: OverridePolicy
metadata:
  name: example-override
  namespace: default
spec:
  resourceSelectors:
  - apiVersion: helm.toolkit.fluxcd.io/v2beta2
    kind: HelmRelease
    name: podinfo
  overrideRules:
  - targetCluster:
      clusterNames:
        - member1
    overriders:
      plaintext:
        - path: "/spec/values"
          operator: add
          value:
            replicaCount: 2
```

2. Apply the manifests to the Karmada-apiserver:

```sh
kubectl apply -f example-override.yaml --kubeconfig ~/.kube/karmada.config
```

The output is similar to:

```
overridepolicy.policy.karmada.io/example-override configured
```

3. After applying the above policy in Karmada control plane, you will find that replicas in member1 has changed to 2, but those in member2 keep the same.

```sh
kubectl --kubeconfig ~/.kube/members.config --context member1 get po
```

The output is similar to:

```
NAME                       READY   STATUS    RESTARTS   AGE
podinfo-68979685bc-6wz6s   1/1     Running   0          6m28s
podinfo-68979685bc-dz9f6   1/1     Running   0          7m42s
```
