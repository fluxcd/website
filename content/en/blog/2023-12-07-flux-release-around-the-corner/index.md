---
author: kingdonb
date: 2023-12-07 00:00:00+00:00
title: Flux v2.2 release is just around the corner!
description: "Flux v2.2.0: Major Helm improvements!"
url: /blog/2023/12/flux-v2-2-release-around-the-corner/
tags: [announcement]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

Now that Flux has reached General Availability, there are planned 3 minor releases per year. So, the maintainer team has been hard at work to create this Flux v2.2.0 release, which is slated to come out next week! Keep your eye out!

While this next release addresses hundreds of issues and has many improvements that will be covered in more detail by a follow-up blog post, we want to highlight one crowning achievement of the next release: Flux helm-controller's reconciliation model has undergone a significant overhaul, this is the one we've all been waiting for!

We hope many Flux users will rejoice in the improvements of the updated helm-controller, and that you'll all update to the latest release. This will help, in particular, with the issue of how the automatic recovery of Helm releases could occasionally get stuck in a pending state.

Two new controls become available in the CLI (and as annotations) that can either [force](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#forcing-a-release) or [reset](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#resetting-remediation-retries) the `HelmRelease`.

In addition, the latest release improves the observability of the Helm release status by reflecting more detailed historic information in the [describe](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#describe-the-helmrelease) output and in the [status](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#history) of the HelmRelease object.

The long-awaited [Drift Detection](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#drift-detection) feature also received an update. Having first been introduced and tested as a global feature flag, the new release introduces the ability to enable drift detection on a per-object basis.

This includes the option to ignore drift in specific fields using Kustomize-like target selectors and JSON pointer paths, which helps to reduce the noise and prevent upgrades from infinitely cycling. Helm Drift detection and correction also is no longer experimental since this release. To opt-in through `HelmRelease.spec.driftDetection` in the `v2beta2` API, enable Drift Detection mode.

An [example below](https://github.com/fluxcd/helm-controller/blob/64fed65148342578c1ed4b2155cd81852c54557a/docs/spec/v2beta2/helmreleases.md#ignore-rules) shows how Drift Detection can be configured to work with an HPA, where some drift is always expected to occur in the `spec.replicas` field:

```yaml
spec:
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/replicas"]
```

There's much more in the upcoming Flux v2.2.0 release such as updates and improvements to Flux source-controller, image-reflector-controller, kustomize-controller, notification-controller, and the Flux CLI!

If you need help with anything or have feedback, we've got a Slack channel, GitHub discussions, and many other ways to get help from the Flux maintainers, contributors, and community: [fluxcd.io/support/](https://fluxcd.io/support/)

