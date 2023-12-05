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

While this next release addresses [hundreds of issues and has many improvements](https://github.com/fluxcd/flux2/issues/4410) that will be covered in more detail by a follow-up blog post, we want to highlight one crowning achievement of the next release: Flux helm-controller's reconciliation model has undergone a significant overhaul, this is the one we've all been waiting for!

We hope many Flux users will rejoice in the improvements of the updated helm-controller, and that you'll all update to the latest release. This will help, in particular, with the issue of how the automatic recovery of releases could occasionally get stuck in a pending state. In addition, the latest release improves the observability of the release status by reflecting more detailed historic information in the status of the HelmRelease object.

Lastly, the new release introduces the ability to enable drift detection on a per-object basis. This includes the option to ignore drift in specific fields using Kustomize-like target selectors and JSON pointer paths, which helps to reduce the noise and prevent upgrades from infinitely cycling. Helm Drift detection and correction also is no longer experimental since this release. Opt-in through `HelmRelease.spec.driftDetection` in the `v2beta2` API.

There's much more in the upcoming Flux v2.2.0 release such as updates and improvements to Flux source-controller, image-reflector-controller, kustomize-controller, notification-controller, and the Flux CLI!

If you get stuck with anything or have feedback, we've got a Slack channel, GitHub discussions, and many other ways to get help from the Flux maintainers, contributors, and community: [fluxcd.io/support/](https://fluxcd.io/support/)

