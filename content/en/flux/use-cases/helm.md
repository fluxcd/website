---
title: Flux for Helm Users
linkTitle: Helm
description: "Declarative Helming with Flux Helm controller."
weight: 30
---

Welcome Helm users!
We think Flux's Helm Controller is the best way to do Helm according to GitOps principles,
and we're dedicated to doing what we can to help you feel the same way.

## What Does Flux add to Helm?

Helm 3 was designed with both a client and an SDK, but no running software agents.
This architecture intended anything outside of the client scope to be addressed by other tools in the ecosystem,
which could then make use of Helm's SDK.

Built on Kubernetes controller-runtime, Flux's Helm Controller is an example of a mature software
agent that uses Helm's SDK to full effect.

Flux's biggest addition to Helm is a structured declaration layer for your releases that
automatically gets reconciled to your cluster based on your configured rules:

- While the Helm client commands let you imperatively do things
- Flux Helm Custom Resources let you declare what you want the Helm SDK to do automatically

Additional benefits Flux adds to Helm include:

- Managing / structuring multiple environments
- A control loop, with configurable retry logic
- Automated drift detection between the desired and actual state of your operations
- Automated responses to that drift, including reconciliation, notifications, and unified logging

## Prerequisites

To follow along you'll need a Kubernetes cluster with Flux installed on it.
Please see the [get started guide](../get-started/index.md)
or the [installation guide](../installation/).


## Getting Started

The simplest way to explain is by example.
Lets translate imperative Helm commands to Flux Helm Controller Custom Resources:

Helm client:

```sh
helm repo add flagger https://flagger.app
helm install my-flagger flagger/flagger \
  --version 1.28.0 
```

Flux client:

Clone your bootstrap repository to your local machine and create a `flagger` directory in your bootstrap path.
```sh
git clone <bootstrap-repo> 
cd <bootstrap-path>
mkdir flagger
```

```sh
flux create source helm flagger --url https://flagger.app --export > flagger/helmrepo.yaml
flux create helmrelease flagger --chart flagger \
  --source HelmRepository/flagger \
  --chart-version '*' \
  --export > flagger/helmrelease.yaml
```

These commands save the YAML for the Flux helm custom resources to the specified file. When these resources are pushed to the 
repository, Flux applies them on the cluster and the Flux Helm Controller automatically reconciles these instructions 
with the running state of your cluster based on your configured rules. Alternatively, you can run the commands without 
the  `--export` command and this will apply the resources directly on your cluster.

Let’s check out what the Custom Resource files look like:

```yaml
# flagger/helmrepo.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: flagger
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://flagger.app
```

```yaml
# flagger/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: flagger
  namespace: flux-system
spec:
  chart:
    spec:
      chart: flagger
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: flagger
      version: '*'
  interval: 1m0s
```

Once these are applied to your cluster, the Flux Helm Controller automatically
uses the Helm SDK to do your bidding according to the rules you've set.

Why is this important?
If you or your team has ever collaborated with multiple engineers on one or more apps,
and/or in more than one namespace or cluster, you probably have a good idea of how declarative,
automatic reconciliation can help solve common problems.
If not, or either way, you may want to check out this [short introduction to GitOps](https://youtu.be/r-upyR-cfDY).

## Customizing Your Release

While Helm charts are usually installable using default configurations,
users will often customize charts with their preferred configuration
by [overriding the default values](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing).
The Helm client allows this by imperatively specifying override values with `--set` on the command line,
and in additional `--values` files. For example:

```sh
helm install my-flagger flagger/flagger --set resource.limit.memory=1Gi
```

and

```sh
helm install my-flagger flagger/flagger --values ci/kind-values.yaml
```

where `ci/kind-values.yaml` contains:

```yaml
resource:
  limit:
    memory: 1Gi
```

Flux Helm Controller allows these same YAML values overrides on the `HelmRelease` CRD.
These can be declared directly in `spec.values`:

```yaml
spec:
  values:
    resource:
      limit:
        memory: 1Gi
```

and defined in `spec.valuesFrom` as a list of `ConfigMap` and `Secret` resources from which to draw values,
allowing reusability and/or greater security.
See `HelmRelease` CRD [values overrides](../components/helm/helmreleases.md#values-overrides)
documentation for the latest spec.

## Managing Secrets and ConfigMaps

You may manage these `ConfigMap` and `Secret` resources any way you wish,
but there are several benefits to managing these with the Flux Kustomize Controller.

It is fairly straigtforward to use Kustomize `configMapGenerator`
to [trigger a Helm release upgrade every time the encoded values change](../guides/helmreleases.md#refer-to-values-in-configmaps-generated-with-kustomize).
This common use case currently solveable in Helm
by [adding specially crafted annotations](https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments)
to a chart. The Flux Kustomize Controller method allows you to accomplish this
on any chart without additional templated annotations.

You may also use Kustomize Controller
built-in [Mozilla SOPS integration](../components/kustomize/kustomization.md#secrets-decryption)
to securely manage your encrypted secrets stored in git.
See the [Flux SOPS guide](../guides/mozilla-sops.md) for step-by-step instructions through various use cases.

## Automatic Release Upgrades

If you want Helm Controller to automatically upgrade your releases when a new chart version is available
in the release's referenced `HelmRepository`,
you may specify a SemVer range (i.e. `>=4.0.0 <5.0.0`) instead of a fixed version.

This is useful if your release should use a fixed MAJOR chart version,
but want the latest MINOR or PATCH versions as they become available.

For full SemVer range syntax,
see `Masterminds/semver`
[Checking Version Constraints](https://github.com/Masterminds/semver/blob/master/README.md#checking-version-constraints)
documentation.

## Automatic Uninstalls and Rollback

The Helm Controller offers an extensive set of configuration options to remediate when a Helm release fails,
using [spec.install.remediation](../components/helm/api.md#helm.toolkit.fluxcd.io/v2beta1.InstallRemediation),
[spec.upgrade.remediation](../components/helm/api.md#helm.toolkit.fluxcd.io/v2beta1.UpgradeRemediation),
[spec.rollback](../components/helm/api.md#helm.toolkit.fluxcd.io/v2beta1.Rollback)
and [spec.uninstall](../components/helm/api.md#helm.toolkit.fluxcd.io/v2beta1.Uninstall).
Features include the option to remediate with an uninstall after an upgrade failure,
and the option to keep a failed release for debugging purposes when it has run out of retries.

Here is an example for configuring automated uninstalls (for all available fields,
consult the `InstallRemediation` and `Uninstall` API references linked above):

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-release
  namespace: default
spec:
  # ...omitted for brevity
  install:
    # Remediation configuration for when the Helm install
    # (or sequent Helm test) action fails
    remediation:
      # Number of retries that should be attempted on failures before
      # bailing, a negative integer equals to unlimited retries
      retries: -1
  # Configuration options for the Helm uninstall action
  uninstall:
    timeout: 5m
    disableHooks: false
    keepHistory: false
```

Here is an example of automated rollback configuration (for all available fields,
consult the `UpgradeRemediation` and `Rollback` API references linked above):

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-release
  namespace: default
spec:
  # ...omitted for brevity
  upgrade:
    # Remediaton configuration for when an Helm upgrade action fails
    remediation:
      # Amount of retries to attempt after a failure,
      # setting this to 0 means no remedation will be
      # attempted
      retries: 5
  # Configuration options for the Helm rollback action
  rollback:
    timeout: 5m
    disableWait: false
    disableHooks: false
    recreate: false
    force: false
    cleanupOnFail: false
```

## Next Steps

- [Guides > Manage Helm Releases](../guides/helmreleases.md)
- [Toolkit Components > Helm Controller](../components/helm/_index.md)
- [Migration > Migrate to the Helm Controller](../migration/helm-operator-migration.md)
