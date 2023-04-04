---
title: "Bootstrap cheatsheet"
linkTitle: "Bootstrap"
description: "Showcase various configurations of Flux controllers at bootstrap time."
weight: 29
---

## How to customize Flux

To customize the Flux controllers during bootstrap,
first you'll need to create a Git repository and clone it locally.

Create the file structure required by bootstrap with:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

The Flux controller deployments, container command arguments, node affinity, etc can be customized using
[Kustomize strategic merge patches and JSON patches](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/patchMultipleObjects.md).

You can make changes to all controllers using a single patch or
target a specific controller:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: # manifests generated during bootstrap
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  # target all controllers
  - patch: | 
      # strategic merge or JSON patch
    target:
      kind: Deployment
      labelSelector: "app.kubernetes.io/part-of=flux"
  # target controllers by name
  - patch: |
      # strategic merge or JSON patch
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
  # add a command argument to a single controller
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --concurrent=5
    target:
      kind: Deployment
      name: "image-reflector-controller"
```

Push the changes to main branch:

```sh
git add -A && git commit -m "init flux" && git push
```

And run the bootstrap for `clusters/my-cluster`:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

To make further amendments, pull the changes locally,
edit the kustomization.yaml file, push the changes upstream
and rerun bootstrap.

## Customization examples

### Safe to evict

Allow the cluster autoscaler to evict the Flux controller pods:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          metadata:
            annotations:
              cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

### Node affinity and tolerations

Pin the Flux controllers to specific nodes:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: role
                          operator: In
                          values:
                            - flux
            tolerations:
              - effect: NoSchedule
                key: role
                operator: Equal
                value: flux
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

The above configuration pins Flux to nodes tainted and labeled with:

```sh
kubectl taint nodes <my-node> role=flux:NoSchedule
kubectl label nodes <my-node> role=flux
```

### Increase the number of workers

If Flux is managing hundreds of applications, you may want to increase the number of reconciliations
that can be performed in parallel and bump the resources limits:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --concurrent=20
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --kube-api-qps=500
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --kube-api-burst=1000
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --requeue-dependency=5s
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|source-controller)"
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
                resources:
                  limits:
                    cpu: 2000m
                    memory: 2Gi
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|source-controller)"
```

{{% alert color="info" title="Horizontal scaling" %}}
When vertical scaling is not an option, you can use sharding to horizontally scale
the Flux controllers. For more details please see the [sharding guide](sharding.md).
{{% /alert %}}

### Persistent storage for Flux internal artifacts

Flux maintains a local cache of artifacts acquired from external sources.
By default, the cache is stored in an `EmptyDir` volume, which means that after a restart,
Flux has to restore the local cache by fetching the content of all Git
repositories, Buckets, Helm charts and OCI artifacts. To avoid losing the cached artifacts,
you can configure source-controller with a persistent volume.

Create a Kubernetes PVC definition named `gotk-pvc.yaml` and place it in your `flux-system` directory:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gotk-pvc
  namespace: flux-system
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 2Gi
```

Add the PVC file to the `kustomization.yaml` resources and patch the source-controller volumes:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
  - gotk-pvc.yaml
patches:
  - patch: |
      - op: add
        path: '/spec/template/spec/volumes/-'
        value:
          name: persistent-data
          persistentVolumeClaim:
            claimName: gotk-pvc
      - op: replace
        path: '/spec/template/spec/containers/0/volumeMounts/0'
        value:
          name: persistent-data
          mountPath: /data
    target:
      kind: Deployment
      name: source-controller
```

### Enable Helm repositories caching

For large Helm repository index files, you can enable
caching to reduce the memory footprint of source-controller:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-max-size=10
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-ttl=60m
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --helm-cache-purge-interval=5m
    target:
      kind: Deployment
      name: source-controller
```

When `helm-cache-max-size` is reached, an error is logged and the index is instead
read from file. Cache hits are exposed via the `gotk_cache_events_total` Prometheus
metrics. Use this data to fine-tune the configuration flags.

### Enable Helm drift detection

At present, Helm releases are not by default checked for drift compared to
cluster-state. To enable experimental drift detection, you must add the
`--feature-gates=DetectDrift=true` flag to the helm-controller Deployment.

Enabling it will cause the controller to check for drift on all Helm releases
using a dry-run Server Side Apply, triggering an upgrade if a change is detected.
For detailed information about this feature, [refer to the
documentation](/flux/components/helm/helmreleases/#drift-detection).

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Enable drift detection feature
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=DetectDrift=true
      # Enable debug logging for diff output (optional)
      - op: replace
        path: /spec/template/spec/containers/0/args/2
        value: --log-level=debug
    target:
      kind: Deployment
      name: helm-controller
```

### Enable Helm near OOM detection

When memory usage of the helm-controller exceeds the configured limit, the
controller will forcefully be killed by Kubernetes' OOM killer. This may result
in a Helm release being left in a `pending-*` state which causes the HelmRelease
to get stuck in an `another operation (install/upgrade/rollback) is in progress`
error loop.

To prevent this from happening, the controller offers an OOM watcher which can
be enabled with `--feature-gates=OOMWatch=true`. When enabled, the memory usage
of the controller will be monitored, and a graceful shutdown will be triggered
when it reaches a certain threshold (default 95% utilization).

When gracefully shutting down, running Helm actions may mark the release as
`failed`. Because of this, enabling this feature is best combined with
thoughtful [remediation strategies](/flux/components/helm/helmreleases/#configuring-failure-remediation).

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Enable OOM watch feature
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=OOMWatch=true
      # Threshold at which to trigger a graceful shutdown (optional, default 95%)
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --oom-watch-memory-threshold=95
      # Interval at which to check memory usage (optional, default 500ms)
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --oom-watch-interval=500ms
    target:
      kind: Deployment
      name: helm-controller
```

### Allow Helm DNS lookups

By default, the helm-controller will not perform DNS lookups when rendering Helm
templates in clusters because of potential [security
implications](https://github.com/helm/helm/security/advisories/GHSA-pwcw-6f5g-gxf8).

To enable DNS lookups, you must add the `--feature-gates=AllowDNSLookups=true`
flag to the helm-controller Deployment.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      # Allow Helm DNS lookups
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=AllowDNSLookups=true
    target:
      kind: Deployment
      name: helm-controller
```

### Using HTTP/S proxy for egress traffic

If your cluster must use an HTTP proxy to reach GitHub or other external services,
you must set `NO_PROXY=.cluster.local.,.cluster.local,.svc`
to allow the Flux controllers to talk to each other:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
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
                env:
                  - name: "HTTPS_PROXY"
                    value: "http://proxy.example.com:3129"
                  - name: "NO_PROXY"
                    value: ".cluster.local.,.cluster.local,.svc"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

### Git repository access via SOCKS5 SSH proxy

If your cluster has Internet restrictions, requiring egress traffic to go
through a proxy, you must use a SOCKS5 SSH proxy to be able to reach GitHub
(or other external Git servers) via SSH.

To configure a SOCKS5 proxy set the environment variable `ALL_PROXY` to allow
both source-controller and image-automation-controller to connect through the
proxy.

```
ALL_PROXY=socks5://<proxy-address>:<port>
```

The following is an example of patching the Flux setup kustomization to add the
`ALL_PROXY` environment variable in source-controller and
image-automation-controller:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
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
                env:
                  - name: "ALL_PROXY"
                    value: "socks5://proxy.example.com:1080"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
      name: "(source-controller|image-automation-controller)"
```

### Test release candidates

To test release candidates, you can patch the container image tags:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
images:
  - name: ghcr.io/fluxcd/source-controller
    newTag: rc-254ba51d
  - name: ghcr.io/fluxcd/kustomize-controller
    newTag: rc-ca0a9b8
```

### OpenShift compatibility

Allow Flux controllers to run as non-root:

```shell
#!/usr/bin/env bash
set -e

FLUX_NAMESPACE="flux-system"
FLUX_CONTROLLERS=(
"source-controller"
"kustomize-controller"
"helm-controller"
"notification-controller"
"image-reflector-controller"
"image-automation-controller"
)

for i in ${!FLUX_CONTROLLERS[@]}; do
  oc adm policy add-scc-to-user nonroot system:serviceaccount:${FLUX_NAMESPACE}:${FLUX_CONTROLLERS[$i]}
done
```

Set the user to nobody and delete the seccomp profile from the security context:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
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
```

### IAM Roles for Service Accounts

To allow Flux access to an AWS service such as KMS or S3, after setting up IRSA,
you can annotate the controller service account with the role ARN:

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
        name: kustomize-controller
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<KMS-ROLE-NAME>
    target:
      kind: ServiceAccount
      name: kustomize-controller
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: source-controller
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<S3-ROLE-NAME>
    target:
      kind: ServiceAccount
      name: source-controller
```

### Multi-tenancy lockdown

Lock down Flux on a multi-tenant cluster by disabling cross-namespace references and Kustomize remote bases, and
by setting a default service account:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-cross-namespace-refs=true
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller)"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-remote-bases=true
    target:
      kind: Deployment
      name: "kustomize-controller"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --default-service-account=default
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
  - patch: |
      - op: add
        path: /spec/serviceAccountName
        value: kustomize-controller
    target:
      kind: Kustomization
      name: "flux-system"
```

### Disable Kubernetes cluster role aggregations

By default, Flux [RBAC](/flux/security/#controller-permissions) grants Kubernetes builtin `view`, `edit` and `admin` roles
access to Flux custom resources. To disable the RBAC aggregation, you can remove the `flux-view` and `flux-edit`
cluster roles with:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: flux
      $patch: delete
    target:
      kind: ClusterRole
      name: "(flux-view|flux-edit)-flux-system"
```

### Enable notifications for third party controllers

Enable notifications for 3rd party Flux controllers such as [tf-controller](https://github.com/weaveworks/tf-controller):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/eventSources/items/properties/kind/enum/-
        value: Terraform
      - op: add
        path: /spec/versions/1/schema/openAPIV3Schema/properties/spec/properties/eventSources/items/properties/kind/enum/-
        value: Terraform
    target:
      kind: CustomResourceDefinition
      name:  alerts.notification.toolkit.fluxcd.io
  - patch: |
      - op: add
        path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/resources/items/properties/kind/enum/-
        value: Terraform
      - op: add
        path: /spec/versions/1/schema/openAPIV3Schema/properties/spec/properties/resources/items/properties/kind/enum/-
        value: Terraform
    target:
      kind: CustomResourceDefinition
      name:  receivers.notification.toolkit.fluxcd.io
  - patch: |
      - op: add
        path: /rules/-
        value:
          apiGroups: [ 'infra.contrib.fluxcd.io' ]
          resources: [ '*' ]
          verbs: [ '*' ]
    target:
      kind: ClusterRole
      name:  crd-controller-flux-system
```
