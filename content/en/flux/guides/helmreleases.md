---
title: "Manage Helm Releases"
linkTitle: "Manage Helm Releases"
description: "Manage Helm Releases in a declarative manner with Flux."
weight: 20
card:
  name: tasks
  weight: 30
---

The [helm-controller](../components/helm/_index.md) allows you to
declaratively manage Helm chart releases with Kubernetes manifests.
It makes use of the artifacts produced by the
[source-controller](../components/source/_index.md) from
`HelmRepository`, `GitRepository`, `Bucket` and `HelmChart` resources.
The helm-controller is part of the default toolkit installation.

## Prerequisites

To follow this guide you'll need a Kubernetes cluster with the GitOps
toolkit controllers installed on it.
Please see the [get started guide](../get-started/index.md)
or the [installation guide](../installation/).

## Define a chart source

To be able to release a Helm chart, the source that contains the chart
(either a `HelmRepository`, `GitRepository`, or `Bucket`) has to be known
first to the source-controller, so that the `HelmRelease` can reference
to it.

### Helm repository

Helm repositories are the recommended source to retrieve Helm charts
from, as they are lightweight in processing and make it possible to
configure a semantic version selector for the chart version that should
be released.

They can be declared by creating a `HelmRepository` resource.

#### Helm HTTP/S repository

The source-controller will fetch the Helm repository index for this
resource on an interval and expose it as an artifact:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 1m
  url: https://stefanprodan.github.io/podinfo
```

The `interval` defines at which interval the Helm repository index
is fetched, and should be at least `1m`. Setting this to a higher
value means newer chart versions will be detected at a slower pace,
a push-based fetch can be introduced using [webhook receivers](webhook-receivers.md)

The `url` can be any HTTP/S Helm repository URL.

{{% alert color="info" title="Authentication" %}}
HTTP/S basic and TLS authentication can be configured for private
Helm repositories. See the [`HelmRepository` CRD docs](../components/source/helmrepositories.md)
for more details.
{{% /alert %}}

#### Helm repository authentication with credentials

In order to use a private Helm repository, you may need to provide the credentials.

For HTTP/S repositories, the credentials can be provided as a secret reference with
basic authentication.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 1m
  url: https://stefanprodan.github.io/podinfo
  secretRef:
    name: example-user
---
apiVersion: v1
kind: Secret
metadata:
  name: example-user
  namespace: default
stringData:
  username: example
  password: "123456"
```

### Git repository

Charts from Git repositories can be released by declaring a
`GitRepository`, the source-controller will fetch the contents of the
repository on an interval and expose it as an artifact.

The source-controller can build and expose Helm charts as artifacts
from the contents of the `GitRepository` artifact (more about this
later on in the guide).

An example `GitRepository`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/stefanprodan/podinfo
  ref:
    branch: master
  ignore: |
    # exclude all
    /*
    # include charts directory
    !/charts/
```

The `interval` defines at which interval the Git repository contents
are fetched, and should be at least `1m`. Setting this to a higher
value means newer chart versions will be detected at a slower pace,
a push-based fetch can be introduced using [webhook receivers](webhook-receivers.md)

The `url` can be any HTTP/S or SSH address (the latter requiring
authentication).

The `ref` defines the checkout strategy, and is set to follow the
`master` branch in the above example. For other strategies like
tags or commits, see the [`GitRepository` CRD docs](../components/source/gitrepositories.md).

The `ignore` defines file and folder exclusion for the
artifact produced, and follows the [`.gitignore` pattern
format](https://git-scm.com/docs/gitignore#_pattern_format).
The above example only includes the `charts` directory of the
repository and omits all other files.

{{% alert color="info" title="Authentication" %}}
HTTP/S basic and SSH authentication can be configured for private
Git repositories. See the [`GitRepository` CRD docs](../components/source/gitrepositories.md)
for more details.
{{% /alert %}}

### Cloud Storage

It is inadvisable while still possible to use a `Bucket` as a source for a `HelmRelease`,
as the source-controller will download the whole storage bucket at each sync. The
bucket can easily become very large if there are frequent releases of multiple charts
that are stored in the same bucket.

A better option is to use an [OCI registry for chart storage](#oci-repository).

### OCI repository

Helm charts stored in an OCI registry, can be retrieved by declaring an `OCIRepository`.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: podinfo
spec:
  interval: 5m0s
  url: oci://ghcr.io/stefanprodan/charts/podinfo
  ref:
    semver: "^6.5.0"
```

The source-controller will fetch the Helm chart from the OCI registry namespace 
on an interval and expose it as an artifact.

The `interval` defines the interval at which the OCI repository contents
are fetched, and should be at least `1m`. Setting this to a higher
value means newer chart versions will be detected at a slower pace,
a push-based fetch can be introduced using [webhook receivers](webhook-receivers.md).

The `url` has to point to a registry repository and start with prefix `oci://`.

The `ref` defines the checkout strategy, and can be one of `tag`, `digest` or `semver`.
When using `semver`, an optional `semverFilter` can be provided to filter the tags.
See the [`OCIRepository` CRD docs](../components/source/ocirepositories.md) for more details.

{{% alert color="info" title="Authentication" %}}
HTTP/S authentication and contextual login can be configured for private
OCI registries. See the [`OCIRepository` CRD docs](../components/source/ocirepositories.md)
for more details.
{{% /alert %}}

## Define a Helm release

To release a Helm chart, a `HelmRelease` resource has to be created. The `HelmRelease`
resources can either reference an existing `OCIRepository` or `Helmchart` resource,
or it creates a new `HelmChart` resource and manages it.

### Using a chart template

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 10m
  chart:
    spec:
      chart: <name|path>
      version: '4.0.x'
      sourceRef:
        kind: <HelmRepository|GitRepository|Bucket>
        name: podinfo
        namespace: flux-system
      interval: 10m
  values:
    replicaCount: 2
```

The `.chart.spec` values are used by the helm-controller as a template
to create a new `HelmChart` resource in the same namespace as the
`.sourceRef`. The source-controller will then look up the chart in the
artifact of the referenced source, and either fetch the chart for a
`HelmRepository`, or build it from a `GitRepository` or `Bucket`.
It will then make it available as a `HelmChart` artifact to be used by
the helm-controller.

The `.chart.spec.chart` can either contain:

* The name of the chart as made available by the `HelmRepository`
  (without any aliases), for example: `podinfo`
* The relative path the chart can be found at in the `GitRepository`
  or `Bucket`, for example: `./charts/podinfo`
* The relative path the chart package can be found at in the
  `GitRepository` or `Bucket`, for example: `./charts/podinfo-1.2.3.tgz`

The `.chart.spec.version` can be a fixed semver, or any semver range
(i.e. `>=4.0.0 <5.0.0`). It is only taken into account for `HelmRelease`
resources that reference a `HelmRepository` source.

{{% alert color="info" title="Advanced configuration" %}}
The `HelmRelease` offers an extensive set of configurable flags
for finer grain control over how Helm actions are performed.
See the [`HelmRelease` CRD docs](../components/helm/helmreleases.md)
for more details.
{{% /alert %}}

### Using a chart reference

It is possible to reference a chart directly from an `OCIRepository`:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
spec:
  chartRef:
    kind: OCIRepository
    name: podinfo
    namespace: flux-system
  interval: 10m
  values:
    replicaCount: 2
```


Or a `HelmChart`:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
spec:
  chartRef:
    kind: HelmChart
    name: podinfo
    namespace: flux-system
  interval: 10m
  values:
    replicaCount: 2
```

The `.chartRef` field is used to reference a `OCIRepository` or `HelmChart` resource.
The helm-controller will then look up the chart in the artifact of the referenced source,
and fetch it directly.

The pros of using a chart reference are:
- The chart is fetched directly from the source, without the need to create a `HelmChart`
  resource for the specific `HelmRelease`. This can reduce the number of resources
  in the cluster.
- In the case of a `OCIRepository`, the fact that it is possible to pin to a
  specific `tag` or `digest` makes it easier to enforce a specific change, and
  is more flexible overall.

**Note**: When switching from a `.chart.spec` to a `.chartRef`, the old `HelmChart`
resource is garbage collected by the helm-controller.

## Refer to values in `ConfigMaps` generated with Kustomize

It is possible to use Kustomize [ConfigMap generator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/)
to trigger a Helm release upgrade every time the encoded values change.

First create a `kustomizeconfig.yaml` for Kustomize to be able to patch
`ConfigMaps` referenced in `HelmRelease` manifests:

```yaml
nameReference:
- kind: ConfigMap
  version: v1
  fieldSpecs:
  - path: spec/valuesFrom/name
    kind: HelmRelease
```

Create a `HelmRelease` definition that references a `ConfigMap`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo
spec:
  interval: 10m
  releaseName: podinfo
  chart:
    spec:
      chart: podinfo
      sourceRef:
        kind: HelmRepository
        name: podinfo
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
```

Create a `kustomization.yaml` that generates the `ConfigMap` using our kustomize config:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo
resources:
  - namespace.yaml
  - repository.yaml
  - release.yaml
configMapGenerator:
  - name: podinfo-values
    files:
      - values.yaml=my-values.yaml
configurations:
  - kustomizeconfig.yaml
```

When [kustomize-controller](../components/kustomize/_index.md) reconciles the above manifests, it will generate
a unique name of the `ConfigMap` every time `my-values.yaml` content is updated in Git:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo
spec:
  valuesFrom:
  - kind: ConfigMap
    name: podinfo-values-2mh2t8m94h
```

{{% alert color="info" title="Garbage Collection" %}}
Stale `ConfigMaps`, previously generated by Kustomize, will be
removed from the cluster by kustomize-controller if [pruning](/flux/components/kustomize/kustomizations/#prune)
is enabled.
{{% /alert %}}

## Refer to values in Secret generated with Kustomize and SOPS

It is possible to use Kustomize [Secret generator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/secretgenerator/)
to trigger a Helm release upgrade every time the encrypted secret values change.

A SOPS configuration for your cluster is required first. Follow the [Manage Kubernetes secrets with Mozilla SOPS](../mozilla-sops/)
guide. The details of configuring SOPS are out of scope for this entry.

Once you have SOPS configured, create a `kustomizeconfig.yaml` for Kustomize to
be able to patch `Secrets` referenced in `HelmRelease` manifests:

```yaml
nameReference:
- kind: Secret
  version: v1
  fieldSpecs:
  - path: spec/valuesFrom/name
    kind: HelmRelease
```

Create a `HelmRelease` definition that references a `Secret`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo
spec:
  interval: 10m
  releaseName: podinfo
  chart:
    spec:
      chart: podinfo
      sourceRef:
        kind: HelmRepository
        name: podinfo
  valuesFrom:
    - kind: Secret
      name: podinfo-values
```

Ensure that this HelmRelease will be applied from the same Flux Kustomization
that will decrypt the values secret. The encrypted secret data must be housed
in the same Flux Kustomization path as the `HelmRelease` in order to allow
Kustomize's Secret generator function to compose them together with the
Kustomize configuration.

Create a `kustomization.yaml` that generates the `Secret`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo
resources:
  - namespace.yaml
  - repository.yaml
  - release.yaml
secretGenerator:
  - name: podinfo-values
    files:
      - values.yaml=my-values.enc.yaml
configurations:
  - kustomizeconfig.yaml
```

Now `HelmRelease` values can come from an encrypted secret! Read on below to
prepare the secret file and apply it to the cluster in a Flux Kustomization.

#### Encrypting a `values.yaml` with the SOPS CLI

To prepare the encrypted secret, please note there are some divergences from
encrypting a well-formed Kubernetes Secret with metadata and versioning.

Run this command to encrypt to the output file that was named in
`kustomization.yaml` above:
```
$ sops -e --input-type=yaml --output-type=yaml values.yaml > my-values.enc.yaml
```

Commit the `my-values.enc.yaml` file and discard the temp file, being sure not
to accidentally commit secrets to the repository. Read on for more information.

If users have followed the [SOPS guide](../mozilla-sops/) then we likely added a `creation_rules`
entry telling the `sops` CLI how to handle encrypting all YAML secrets, like:

```yaml
# ./apps/sensitive/.sops.yaml
creation_rules:
  - path_regex: ".*\\.yaml"
    encrypted_regex: ^(data|stringData)$
    pgp: KEY_ID_ASDF1234
```

This selects only the `data` or `stringData` fields for encryption, leaving all
the metadata unencrypted, which is the proper way to handle normal, well-formed
`Secrets` according to Flux's SOPS guide.

Since a values file is not a well-formed `Secret` that rule would fail to
encrypt the secret. Instead, here, we add a more specific rule which is listed
first, so that our values.yaml file does not get captured by the `*.yaml` rule.

```yaml
# ./apps/sensitive/.sops.yaml
creation_rules:
  - path_regex: .*values.yaml$
    pgp: KEY_ID_ASDF1234
  - path_regex: ".*\\.yaml"
    encrypted_regex: ^(data|stringData)$
    pgp: KEY_ID_ASDF1234
```


The filename was chosen to **not** match with `*.enc` or `*.encrypted` so that
`sops` CLI never infers a binary input type, to avoid that decryption with
`sops my-values.enc.yaml` for editing in-place would also fail.

Be careful not to mix secrets with other non-sensitive data. A note that Helm
stores its values as Kubernetes Secrets internally; if users can read secrets
in the context then they can recover decrypted values using `helm get values`.

## Refer to values inside the chart

It is possible to replace the `values.yaml` with a different file present inside the Helm chart.

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: mongodb
  namespace: mongodb
spec:
  interval: 10m
  chart:
    spec:
      chart: mongodb
      sourceRef:
        kind: HelmRepository
        name: bitnami
      valuesFiles:
        - values.yaml
        - values-production.yaml
  values:
    replicaCount: 5
```

If one or many of the `spec.chart.spec.valuesFiles` don't exist inside the chart,
helm-controller will not be able to fetch the chart. That default behavior can be
overridden by setting `.spec.chart.spec.ignoreMissingValuesFiles`, so a missing
file named in `valuesFiles` will not cause any failure.

To determine why the `HelmChart` fails to produce an artifact, you can inspect the status with:

```sh
$ kubectl get helmcharts --all-namespaces
NAME    READY   STATUS
mongodb False   failed to locate override values file: values-production.yaml
```

## Configure notifications

The default toolkit installation configures the helm-controller to
broadcast events to the [notification-controller](/flux/components/notification).

To receive the events as notifications, a `Provider` needs to be setup
first as described in the [notifications guide](/flux/monitoring/alerts/#define-a-provider).
Once you have set up the `Provider`, create a new `Alert` resource in
the `flux-system` to start receiving notifications about the Helm
release:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: helm-podinfo
  namespace: flux-system
spec:
  providerRef:
    name: slack
  eventSeverity: info
  eventSources:
  - kind: HelmRepository
    name: podinfo
  - kind: HelmChart
    name: default-podinfo
  - kind: HelmRelease
    name: podinfo
    namespace: default
```

![helm-controller alerts](/img/helm-controller-alerts.png)

## Configure webhook receivers

When using semver ranges for Helm releases, you may want to trigger an update
as soon as a new chart version is published to your Helm repository.
In order to notify source-controller about a chart update,
you can [setup webhook receivers](webhook-receivers.md).

First generate a random string and create a secret with a `token` field:

```sh
TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
echo $TOKEN

kubectl -n flux-system create secret generic webhook-token \
--from-literal=token=$TOKEN
```

When using [Harbor](https://goharbor.io/) as your Helm repository, you can define a receiver with:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: helm-podinfo
  namespace: flux-system
spec:
  type: harbor
  secretRef:
    name: webhook-token
  resources:
    - kind: HelmRepository
      name: podinfo
```

The notification-controller generates a unique URL using the provided token and the receiver name/namespace.

Find the URL with:

```sh
$ kubectl -n flux-system get receiver/helm-podinfo

NAME           READY   STATUS
helm-podinfo   True    Receiver initialised with URL: /hook/bed6d00b5555b1603e1f59b94d7fdbca58089cb5663633fb83f2815dc626d92b
```

Log in to the Harbor interface, go to Projects, select a project, and select Webhooks.
Fill the form with:

* Endpoint URL: compose the address using the receiver LB and the generated URL `http://<LoadBalancerAddress>/<ReceiverURL>`
* Auth Header: use the `token` string

With the above settings, when you upload a chart, the following happens:

* Harbor sends the chart push event to the receiver address
* Notification controller validates the authenticity of the payload using the auth header
* Source controller is notified about the changes
* Source controller pulls the changes into the cluster and updates the `HelmChart` version
* Helm controller is notified about the version change and upgrades the release

{{% alert color="info" title="Note" %}}
Besides Harbor, you can define receivers for **GitHub**, **GitLab**, **Bitbucket**
and any other system that supports webhooks e.g. Jenkins, CircleCI, etc.
See the [Receiver CRD docs](../components/notification/receivers.md) for more details.
{{% /alert %}}

## Release when a source revision changes for Git and Cloud Storage

It is possible to create a new chart artifact when a Source's revision has changed, but the
`version` in the Chart.yml has not been bumped, for `GitRepository` and `Bucket` sources.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmChart
metadata:
  name: podinfo
  namespace: default
spec:
  chart: ./charts/podinfo
  sourceRef:
    name: podinfo
    kind: <GitRepository|Bucket>
  interval: 10m
  reconcileStrategy: Revision
```
