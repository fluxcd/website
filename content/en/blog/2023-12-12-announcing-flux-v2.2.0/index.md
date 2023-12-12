---
author: hiddeco
date: 2023-12-12 15:00:00+00:00
title: Announcing Flux 2.2 GA
description: "We are thrilled to announce the release of Flux v2.2.0! Here you will find highlights of new features and improvements in this release, with the primary theme being Helm."
url: /blog/2023/12/flux-v2.2.0/
tags: [announcement]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

We are thrilled to announce the release of [Flux v2.2.0](https://github.com/fluxcd/flux2/releases/tag/v2.2.0)! In this post, we will highlight some of the new features and improvements included in this release, with the primary theme being the many changes made to the [helm-controller](https://fluxcd.io/flux/components/helm/).

This new release will also be demoed by Priyanka "Pinky" Ravi and Max Werner on Monday, December 18. To attend this demo and ask any questions, [you can register here](https://www.meetup.com/weave-user-group/events/297818586/).

## Important things first: API changes

This release is accompanied by a series of (backwards compatible) API changes and introductions. Please refer to the [release notes](https://github.com/fluxcd/flux2/releases/tag/v2.2.0) for a comprehensive list, and make sure to read them before updating your Flux installation.

## Enhanced `HelmRelease` reconciliation model

The reconciliation model of the helm-controller has been rewritten to be able to better determine the state a Helm release is in, to then decide what Helm action should be performed to reach the desired state.

Effectively, this means that the controller is now capable of continuing where it left off, and to run [Helm tests](https://fluxcd.io/flux/components/helm/helmreleases/#test-configuration) as soon as they are enabled without a Helm upgrade having to take place first.

In addition, it now takes note of releases _while they are happening_, instead of making observations _afterward_. Ensuring that when performing a rollback remediation, the version we revert to is always exactly the same as the one previously released by the controller. In cases where it is uncertain about state, it will always decide to (reattempt to) perform a Helm upgrade.

This also allows it with certainty to only count release attempts that did cause a mutation to the Helm storage as failures towards retry attempts, improving continuity due to it retrying instantly instead of remediating first.

## Improved observability of Helm releases

An additional thing the enhanced reconciliation model allowed us to work on is making improvements to how we report state back to you, as a user.

The improvements range from the introduction of `Reconciling` and `Stalled` Condition types to become [`kstatus` compatible](https://github.com/kubernetes-sigs/cli-utils/tree/master/pkg/kstatus), to an enriched overview of Helm releases up to the previous successful release in the Status, and more informative Kubernetes Event and Condition messages.

```console
Events:
  Type    Reason            Age   From             Message
  ----    ------            ----  ----             -------
  Normal  HelmChartCreated  25s   helm-controller  Created HelmChart/demo/demo-podinfo with SourceRef 'HelmRepository/demo/podinfo'
  Normal  InstallSucceeded  20s   helm-controller  Helm install succeeded for release demo/podinfo.v1 with chart podinfo@6.5.3
  Normal  TestSucceeded     12s   helm-controller  Helm test succeeded for release demo/podinfo.v1 with chart podinfo@6.5.3: 3 test hooks completed successfully
```

For more details around these changes, refer to the [Status section](https://fluxcd.io/flux/components/helm/helmreleases/#helmrelease-status) in the HelmRelease v2beta2 specification.

## Recovery from `pending-*` Helm release state

A much-reported issue was the helm-controller being unable to recover from `another operation (install/upgrade/rollback) is in progress` errors, which could occur when the controller Pod was forcefully killed. From this release on, the controller will recover from such errors by unlocking the Helm release from a `pending-*` to a `failed` state, and retrying it with a Helm upgrade.

## Helm Release drift detection and correction

Around April we launched cluster state drift detection and correction for Helm releases as an experimental feature. At that time, it could only be enabled using a controller global feature flag, making it impractical to use at scale due to the wide variability in charts and unpredictability of the effects on some Helm charts.

For charts with lifecycle hooks, or cluster resources like Horizontal/Vertical Pod Autoscalers for which controllers may write updates back into their own spec, those updates would always be considered as drift by the helm-controller unless the resource would be ignored in full.

To address the above pain points, Helm drift detection can now be enabled on the `HelmRelease` itself, while also allowing you to ignore specific fields using [JSON Pointers](https://datatracker.ietf.org/doc/html/rfc6901):

```yaml
spec:
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/replicas"]
        target:
          kind: Deployment
```

Using these settings, any drift detected will now be corrected by recreating and patching the Kubernetes objects (instead of doing a Helm upgrade) while changes to the `.spec.replicas` fields for Deployments will be ignored.

For more information, refer to the [drift detection section](https://fluxcd.io/flux/components/helm/helmreleases/#drift-detection) in the HelmRelease v2beta2 specifiation.

## Forcing and retrying Helm releases

Another much-reported issue was the impractical steps one had to take to recover from "retries exhausted" errors. To instruct the helm-controller to retry installing or upgrading a Helm release when it is out of retries, you can now either:

- Instruct it to reset the failure counts, allowing it to retry the number of times as configured in the remediation strategy

  ```shell
  flux reconcile helmrelease <release> --reset
  ```

- Instruct it to force a one-off Helm install or upgrade

  ```shell
  flux reconcile helmrelease <release> --force
  ```

For in-depth explanations about these new command options, refer to the ["resetting remediation retries"](https://fluxcd.io/flux/components/helm/helmreleases/#resetting-remediation-retries) and ["forcing a release"](https://fluxcd.io/flux/components/helm/helmreleases/#forcing-a-release) sections in the HelmRelease v2beta2 specification.

## Benchmark results

To measure the real world impact of the helm-controller overhaul, we have set up benchmarks that measure Mean Time To Production (MTTP). The MTTP benchmark measures the time it takes for Flux to deploy application changes into production. Below are the results of the benchmark that ran on a GitHub hosted runner (Ubuntu, 16 cores):

| Objects | Type          | Flux component       | Duration | Max Memory |
|---------|---------------|----------------------|----------|------------|
| 100     | OCIRepository | source-controller    | 25s      | 38Mi       |
| 100     | Kustomization | kustomize-controller | 27s      | 32Mi       |
| 100     | HelmChart     | source-controller    | 25s      | 40Mi       |
| 100     | HelmRelease   | helm-controller      | 31s      | 140Mi      |
| 500     | OCIRepository | source-controller    | 45s      | 65Mi       |
| 500     | Kustomization | kustomize-controller | 2m2s     | 72Mi       |
| 500     | HelmChart     | source-controller    | 45s      | 68Mi       |
| 500     | HelmRelease   | helm-controller      | 2m55s    | 350Mi      |
| 1000    | OCIRepository | source-controller    | 1m30s    | 67Mi       |
| 1000    | Kustomization | kustomize-controller | 4m15s    | 112Mi      |
| 1000    | HelmChart     | source-controller    | 1m30s    | 110Mi      |
| 1000    | HelmRelease   | helm-controller      | 8m2s     | 620Mi      |

> The benchmark uses a single application ([podinfo](https://github.com/stefanprodan/podinfo)) for all tests with intervals set to `60m`. The results may change when deploying Flux objects with a different configuration.

For more information about the benchmark setup and how you can run them on your machine, check out the [fluxcd/flux-benchmark](https://github.com/fluxcd/flux-benchmark) repository.

## Breaking changes to Kustomizations

All Flux components have been updated from Kustomize v5.0.3 to [v5.3.0](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.3.0).

You should be aware that this update comes with a breaking change in Kustomize, as components are now applied after generators. If you use Kustomize components or `.spec.components` in Kustomizations along with generators, then please make necessary changes before upgrading to avoid any undesirable behavior. For more information, see the relevant [Kustomize issue](https://github.com/kubernetes-sigs/kustomize/issues/5141).

## Other notable changes

- `flux install` and `flux bootstrap` now have guardrails to protect users from destructive operations.
- Gitea support has been added to `flux bootstrap`. To bootstrap Flux onto a cluster using Gitea as the Git provider, run `flux bootstrap gitea --repository <repo> --owner <owner>`.
- The OIDC issuer and identity subject can now be verified for images signed using Cosign. Refer to the [HelmChart](https://fluxcd.io/flux/components/source/helmcharts/#keyless-verification) and [OCIRepository](https://fluxcd.io/flux/components/source/ocirepositories/#keyless-verification) specifications for more information.
- [Prefix based file filtering](https://fluxcd.io/flux/components/source/buckets/#prefix) support has been added to the Bucket API for `generic`, `aws` and `gcp` providers.
- Support for insecure (non-TLS HTTP) container registries has been added to the [ImageRepository](https://fluxcd.io/flux/components/image/imagerepositories/#insecure) and [HelmRepository](https://fluxcd.io/flux/components/source/helmrepositories/#insecure) APIs.
- The Flux alerting capabilities have been extended with [NATS](https://fluxcd.io/flux/components/notification/provider/#nats) and [Bitbucket Server & Data Center](https://fluxcd.io/flux/components/notification/provider/#bitbucket-serverdata-center) support.

## Installing or upgrading Flux

To install Flux, take a look at our [installation](https://fluxcd.io/flux/installation/) and [get started](https://fluxcd.io/flux/get-started/) guides.

To upgrade Flux from `v2.x` to `v2.2.0`, either [rerun `flux bootstrap`](https://fluxcd.io/flux/installation/#bootstrap-upgrade) or use the [Flux GitHub Action](https://github.com/fluxcd/flux2/tree/main/action).

To upgrade the APIs, make sure the new Custom Resource Definitions and controllers are deployed, and then change the manifests in Git:

1. Set  `apiVersion: helm.toolkit.fluxcd.io/v2beta2` in the YAML files that contain `HelmRelease` definitions.
2. Set  `apiVersion: notification.toolkit.fluxcd.io/v1beta3` in the YAML files that contain `Alert` and `Provider` definitions.
3. Commit, push and reconcile the API version changes.

Bumping the APIs version in manifests can be done gradually. It is advised to not delay this procedure as the deprecated versions will be removed after 6 months.

## Over and out

If you have any questions, or simply just like what you read and want to get involved. Here are a few good ways to reach us:

- Join our [upcoming dev meetings](https://fluxcd.io/community/#meetings).
- Join the [Flux mailing list](https://lists.cncf.io/g/cncf-flux-dev) and let us know what you need help with.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/).
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions).
- Follow [Flux on Twitter](https://twitter.com/fluxcd), or join the
  [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).
