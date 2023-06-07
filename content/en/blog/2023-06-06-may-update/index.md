---
author: somtochiama
date: 2023-06-06 20:30:00+00:00
title: May 2023 Update
description: "Flux v2.0.0-rc5 is out with lots of improvements, please test and give us feedback. We went to GitOpsCon / Open Source Summit - check out our talks from these events. That plus lots of news from our contributors and ecosystem."
url: /blog/2023/06/may-2023-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

<!--

Have a look at these documents

- internal_docs/how-to-do-the-monthly-update.md
  online: https://github.com/fluxcd/website/blob/main/internal_docs/how-to-do-the-monthly-update.md
- internal_docs/how-to-write-a-blog-post.md
  online: https://github.com/fluxcd/website/blob/main/internal_docs/how-to-write-a-blog-post.md

to get more background on how to publish this blog post.

-->

May was packed with exciting stories from Flux users, newly updated
Flux adopters, contributors, contributions and a new GA release candidate!
Also, don’t miss future Flux Bug Scrubs using ChatGPT.

## Flux technology things to know

### Three more Flux release candidates! Many improvements - Please test

On our path to GA, we released [v2.0.0-rc5](https://github.com/fluxcd/flux2/releases/tag/v2.0.0-rc.5),
the fifth release candidate for the 2.0.0 release. It includes many fixes,
so you are very much encouraged to upgrade to this latest version - even though
it carries "RC" in its version number, it is the most stable Flux release to date.
Users are advised to upgrade from v0.41 and older versions to v2.0.0-rc.5 as soon as possible.

#### Fixes and improvements

- Starting with this version, source-controller, kustomize-controller and
  helm-controller pods are marked as
  [system-cluster-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/).
- The `Alert` v1beta2 API has two new optional fields. `.spec.inclusionList` for
  fine-grained control over events filtering (notification-controller) and 
  `.spec.metadata` that allows users to enrich the alerts with information 
  about the cluster name, region, environment, etc.
- New command `flux reconcile source chart` for pulling Helm OCI charts on-demand
  from container registries (CLI).
- Support annotated Git tags with .spec.ref.name in GitRepository (source-controller).
- The deprecated field `.status.url` was removed from the `Receiver` v1
  API (notification-controller).
- Add support for commit signing using OpenPGP keys with
  passphrases (image-automation-controller).
- Fix bootstrap for BitBucket Server (CLI).
- Fix secrets decryption when using Azure Key Vault (kustomize-controller).
- Fix drift detection for renamed HelmReleases (helm-controller).
- Improve performance when handling webhook receivers (notification-controller).
- Improve the detection of values changes for HelmReleases by stable 
  sorting them by key (helm-controller)
- Update cosign to v2 (source-controller)
- Support for Helm 3.12.0 and Kustomize v5.0.3.

To upgrade from v0.x to v2.0.0-rc.5, please see
[the procedure documented in RC.1](https://github.com/fluxcd/flux2/releases/tag/v2.0.0-rc.1).

:warning: Note that Kubernetes 1.27.0 contains a regression bug that affects
Flux, it is recommended to upgrade Kubernetes to 1.27.1 or newer. The upgrade to
Kustomize v5 also contains breaking changes, please consult their
[CHANGELOG](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.0.0) for more details.

Big thanks to all the Flux contributors that helped us with this release!

### Security news

All components have been updated to patch vulnerabilities in Docker (CVE-2023-28840,
CVE-2023-28841, CVE-2023-28842) and Sigstore (CVE-2023-30551, CVE-2023-33199).

### Flagger 1.31.0

This release adds support for Linkerd 2.13. Furthermore, a bug which led the confirm-rollout
webhook to be executed at every step of the Canary instead of only being executed before the
canary deployment is scaled up, has been fixed.

:warning: This release contains some breaking changes for the Linkerd integration.
Please see the [CHANGELOG](https://github.com/fluxcd/flagger/blob/main/CHANGELOG.md#1310)
on how to upgrade.

## News from Flux users & the Community!

### Newly posted Flux adopters!

{{< gallery match="logos/*" sortOrder="desc" rowHeight="150" margins="5"
            thumbnailResizeOptions="600x600 q90 Lanczos"
            previewType="blur" embedPreview=true lastRow="nojustify" >}}

- [Blablacar](https://www.blablacar.com/): a long distance carpooling platform that connects
  drivers with empty seats and passengers to share travel costs.
- [Nuvme](https://nuvme.com): a consulting firm specializing in cloud application modernization.
- [TTMzero](https://ttmzero.com): a RegTech company that assists financial players
  with pre and post-trade digitization.

Thanks to Horacio Granillo ([@hgranillo](https://github.com/hgranillo)),
Peter König ([@konigpeter](https://github.com/konigpeter)), and Julien Haumont
([@jhaumont](https://github.com/jhaumont)) for taking the time to make these
additions to the Flux adopters list!

*If you have not already done so, [use the instructions here](/adopters/) or
give us a ping and we will help to add you. Not only is it great for us to
get to know and welcome you to our community, it also gives the team a big
boost in morale to see Flux being used across the world.*

### Flux members, contributors, and maintainers!

#### Priyanka Ravi joins as Flux Project Member

We are very happy that Priyanka "Pinky" Ravi [joined us as a Flux
Project Member](https://github.com/fluxcd/community/issues/293).

Over the past years, Pinky spoke at conferences, meetups and elsewhere,
demoing Flux, discussing use-cases and discussing what's new. If you
want to have a look at some of her talks, check out our [resources
section](/resources).

Thanks a lot for everything you have done - we are happy to have you
in our team!

#### Matheus Pimenta joins as a Flux Project Member

We are very happy to have [Matheus Pimenta](https://github.com/fluxcd/community/issues/300)
as a Flux Project Member. Matheus has been very active in the Flux community.
He has been opening issues, participating in discussions and raising pull requests
especially in the notification-controller.

Thanks a lot for everything you have done - we are happy to have you
in our team!

#### Tamao Nakahara joins as Flux Project Member

Tamao has been actively assisting with managing the Flux community
and organizing efforts around getting Flux represented at various
conferences. She is the lead organizer of [GitOps Days](https://www.gitopsdays.com/).

Tamao has done so much for the Flux project. We are happy to welcome
her to the team.

#### Sanskar Jaiswal becomes a Core Maintainer

Sanskar has been making major code contributions to Flux
for a while and is already a Flagger maintainer. He has
been instrumental in getting the improving the git implementation
in Flux and a host of other features.

Thanks for all your contributions to Flux! This is well-deserved.

#### Mehak Saeed selected for Flux's Season of Docs

We are excited to welcome Mehak Saheed who would be working to
improve Flux's documentation during this year's Google Season
of Docs. Mehak is a technical writer with over six years of experience
and has worked on documentation for projects such as [cert-manager](https://cert-manager.io/docs/)
and [Unfurl](https://docs.unfurl.run/).

We look forward to the great work she'll do!

### Share your story at KubeCon NA in Chicago this year! 📆

*If you wish to speak at KubCon NA, reach out to us to collaborate on
proposals on a range of topics related to Kuberentes. We are happy to
provide our writing expertise to your proposal and to collaborate on
ideas. The CFP deadline is June 18, so kindly contact
[tamao@weave.works](mailto:tamao@weave.works) ASAP if you're interested.
The conference is from 6th-9th November in Chicago.*

### Use Cases from Flux users at GitOpsCon / Open Source Summit 2023 in May!

Flux users, contributors, and maintainers spoke at the 2-day co-located event,
[GitOpsCon-CDCon](http://gitopscon.com), as well as at the 3-day core conference,
[Open Source Summit NA 2023](https://events.linuxfoundation.org/open-source-summit-north-america/),
during the week of May 8-12, 2023 in Vancouver, Canada. See below for more talks
from the conference from contributors and maintainers. Here are highlighted talks from Flux users:

- [Keynote Session: GitOps as an Evolution of Kubernetes](https://youtu.be/LHVjp7JeKzE) -
  Flux user and Kubernetes co-creator, Brendan Burns, Corporate Vice President
- [Multitenancy - Build Vs. “Buy”: Zcaler’s Journey](https://youtu.be/AIdG4hTr0dk) - Flux users Neeta Rathi & Josh Carlisle, ZScaler
- [Managing Software Upgrades with a kpt, GitLab and Flux Workflow in a Telecom Context](https://youtu.be/y--oZrATl6c) - Flux user, Peter Wörndle, Ericsson
- [Flux at the Point of Change - Using the K8s Golang SDK and the Flux Api to Automatically Fix and Deploy CVEs in Your Base Images](https://youtu.be/TEeZ1gYWwrw) - Flux user, Bryan Oliver, Thoughtworks, Inc.
- [Kubernetes Quick Wins and Migration Best Practices: RingCentral Example](https://youtu.be/pVuwrstpET4) - Flux user, Ivan Anisimov, RingCentral
- [Deliver a Multicloud Application with Flux and Carvel](https://youtu.be/UFcO9oZMbdA) - Flux ecosystem user, Peter Tran, VMware
- [High-Security, Zero-Connectivity & Air-Gapped Clouds: Delivering Complex Software with the Open Component Model & Flux](https://youtu.be/9axzrzhrfgw) - Flux user, Dan Small, SAP & Mohamed Ahmed, Weaveworks 
- [Delivering Secure & Compliant Software Components with the Open Component Model & GitOps](https://youtu.be/LBD4EYDYlCU) - Flux user, Dan Small, SAP SE
- [Extending Observability to the Application Lifecycle with ArgoCD, Flux and Keptn](https://youtu.be/RgzGNY1uy3U) - Flux users Ana Margarita Medina, Lightstep & Adam Gardner, Dynatrace

### DevOps Days Medellin, Colombia

[David Caballero](https://cv.dcaballero.net/) gave a talk this month on Flux
and shared slides and other resources in the [CNCF Flux slack](https://cloud-native.slack.com/archives/CLAJ40HV3/p1684432848208149). Check it out!

### Talks on Flux+GitLab, Flux+ARM64, Flux+Terraform, Flux+VS Code, Flux+WASM and more from GitOpsCon-CDCon / Open Source Summit 2023

Here are additional talks from [GitOpsCon-CDCon](http://gitopscon.com) and
[Open Source Summit NA 2023](https://events.linuxfoundation.org/open-source-summit-north-america/),
during the week of May 8-12, 2023 in Vancouver, Canada. 

#### Talk summaries in The New Stack:

- [Kingdon’s talk](https://thenewstack.io/case-study-a-webassembly-failure-and-lessons-learned/) on WASM
- GitOps principles quoting [Pinky’s GitOpsCon keynote](https://thenewstack.io/4-core-principles-of-gitops/) panel

#### Talks by Flux contributors and maintainers include:

- [GitOpsCon Keynote panel featuring Flux contributor](https://youtu.be/yGrTxkzjmZA), Priyanka “Pinky” Ravi, Weaveworks 
- [GitLab + Flux!](https://youtu.be/CeCpvJH_RuA) - Priyanka “Pinky” Ravi, Weaveworks & Flux user, Viktor Nagy, GitLab 
- [GitOps Sustainability with Flux and arm64 (full version)](https://youtu.be/KT_Hxr8pGLg)- Tamao Nakahara, Weaveworks & Liz Fong-Jones, Honeycomb
- [Microservices and WASM, Are We There Yet?](https://youtu.be/2eTjGFbOz5E) - Flux user, Will Christensen, Defense Unicorns & Kingdon Barrett, Weaveworks
- [Automate with Terraform + Flux + EKS: Level Up Your Deployments](https://youtu.be/E0OzGADEoik) - Flux contributor, Priyanka "Pinky" Ravi, Weaveworks
- [Exotic Runtime Targets: Ruby and Wasm on Kubernetes and GitOps Delivery Pipelines (15-min version)](https://youtu.be/SLoVn2Ao3qc) - Flux maintainer, Kingdon Barrett, Weaveworks
- [VS Code+Flux: Dev-Driven Automated Deployments Like a Cloud Native Pro (Even if You’re a Beginner)](https://youtu.be/biC7X33o9eI) - Flux ecosystem contributor, Juozas Gaigalas, Weaveworks
- [Level Up Your Deployments: Automate with Terraform + Flux](https://youtu.be/R4rKr4jbvr8) - Flux contributor, Priyanka "Pinky" Ravi, Weaveworks
- [Platform Engineering Done Right: Safe, Secure, & Scalable Multi-Tenant GitOps](https://youtu.be/aScxRi6sjrk) - Flux ecosystem contributor, Juozas Gaigalas, Weaveworks
- [Exotic Runtime Targets: Ruby and Wasm on Kubernetes and GitOps Delivery Pipelines (40-min version)](https://youtu.be/EsAuJmHYWgI) - Flux maintainer, Kingdon Barrett, Weaveworks
- [Lightning Talk: GitOps Sustainability with Flux and arm64 (5-min version)](https://youtu.be/vBQ3wN1c9xU) - Flux contributor, Tamao Nakahara, Weaveworks
- [Community Diversity and Inclusion as Business Metric (and Not Just a Feel-Good Tactic)](https://youtu.be/A-su3Rb7UC8) - Flux contributor, Tamao Nakahara, Weaveworks

{{< gallery match="images/*" sortOrder="desc" rowHeight="250" margins="5"
            thumbnailResizeOptions="900x900 q90 Lanczos"
            previewType="blur" embedPreview=true lastRow="nojustify" >}}

## Upcoming Events

#### Flux project meetings and Flux Bug Scrub+ChatGPT!

Our June 27 and 28 bug scrubs will involve using ChatGPT
Experiment with us and we’ll learn together!
Join the [Weave Online User Group](https://www.meetup.com/Weave-User-Group/)
for updates.

The next dates are going to be:

- 2023-06-07 12:00 UTC, 19:00 CEST [CNCF Flux Project Meeting (early)](/#calendar)
- 2023-06-08 17:00 UTC, 19:00 CEST [The Flux Bug Scrub](/#calendar)
- 2023-06-13 22:00 UTC, 00:00 CEST [The Flux Bug Scrub (AEST)](/#calendar)
- 2023-06-14 12:00 UTC, 14:00 CEST [The Flux Bug Scrub](/#calendar)
- 2023-06-15 15:00 UTC, 17:00 CEST [CNCF Flux Project Meeting (late)](#calendar)
- 2023-06-21 12:00 UTC, 19:00 CEST [CNCF Flux Project Meeting (early)](#calendar)
- 2023-06-22 17:00 UTC, 19:00 CEST [The Flux Bug Scrub](/#calendar)
- 2023-06-27 22:00 UTC, 14:00 CEST [The Flux Bug Scrub (AEST): playing with ChatGPT!](/#calendar)
- 2023-06-28 12:00 UTC, 00:00 CEST [The Flux Bug Scrub: playing with ChatGPT!](/#calendar)
- 2023-06-29 15:00 UTC, 17:00 CEST [CNCF Flux Project Meeting (late)](/#calendar)

Our Flux Bug Scrubs still are happening on a weekly basis and remain one of
the best ways to get involved in Flux. They are a friendly and welcoming way
to learn more about contributing and how Flux is organised as a project.

*We are flexible with subjects and often go with the interests of the
group or of the presenter. If you want to come and join us in either
capacity, just show up or if you have questions, reach out to Kingdon on
Slack.*

## Flux Fun Fact!

Did you know … 
🔩 Flux works with your existing tools: Flux works with your Git providers
(GitHub, GitLab, Bitbucket, can even use s3-compatible buckets as a source),
all major container registries, and all CI workflow providers. GitLab also
announced that Flux is their GitOps tool of choice, so you'll see even more
synergy this year!

## Over and out

If you like what you read and would like to get involved, here are a few good ways to do that:

- Join our [upcoming dev meetings](https://fluxcd.io/community/#meetings).
- Join the [Flux mailing list](https://lists.cncf.io/g/cncf-flux-dev) and let us know what you'd like to see.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/).
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions).
- And if you are completely new to Flux, take a look at our [Get Started guide](https://fluxcd.io/docs/get-started/)
  and give us feedback.
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the discussion in the
  [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).
- We are looking forward to working with you.

:heart: Your Flux maintainer, Somtochi Onyekwere, and project member, Tamao Nakahara.
