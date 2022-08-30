---
author: dholbach
date: 2021-07-02 11:30:00+00:00
title: July 2021 update
description: Stable Flux APIs from 0.16 onwards. 100 Flux releases. Bug Scrub community initiative. New Flagger release, Docs and website updates and lots more!
url: /blog/2021/07/july-2021-update/
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration and where you can get
involved. Read [last month's update
here](/blog/2021/05/june-2021-update/).

Let's recap what happened in June - there has been so much happening!

## From now on Flux APIs will be stable

We moved our APIs to v1beta1, which means that all Flux APIs are stable
from now on. To us this means that Flux is production ready. You can
make use of all these APIs, we'll support them from now on. Going
forward, breaking changes to the beta CRDs will be accompanied by a
conversion mechanism.

Incidentally this also marks the 100th release in the [`fluxcd/flux2`
repo](https://github.com/fluxcd/flux2). :fireworks:

How about you give us a :star: if you like it?

We are very proud of what we put together, here we want to reiterate
some Flux facts - they are sort of our mission statement with Flux.

## Flux Project Facts

1. **🤼 Flux provides GitOps for both apps or
 infrastructure.** With help from Flagger, Flux can
 automate the release process of apps using strategies like
 canaries and A/B rollouts. Flux can also manage any Kubernetes
 resource. Infrastructure and workload dependency management is
 built-in.

2. **🤖 Just push to Git and Flux does the rest.** Flux
   enables application deployment (CD) and progressive delivery (PD)
   through automatic reconciliation. Flux can update container image
   declarations in your YAML and push them automatically back to Git
   for you (based on new image tags discovered via scanning).

3. **🔩 Flux plays nice with your existing tools**: your Git
   providers (GitHub, GitLab, Bitbucket, can even use s3-compatible
   buckets as a source), all major container registries, and all CI
   workflow providers.

4. **☸️ Flux works with any Kubernetes and all common Kubernetes
   tooling**: Kustomize, Helm, RBAC, and policy-driven
   validation (OPA, Kyverno, admission controllers) so it simply
   falls into place.

5. **🤹 Flux does Multi-Tenancy (and "Multi-everything")**:
   Flux uses true Kubernetes RBAC via impersonation and supports
   multiple Git repositories. Multi-cluster infrastructure and apps
   work out of the box with Cluster API: Flux can use one Kubernetes
   cluster to manage apps in either the same or other clusters, spin
   up additional clusters themselves, and manage clusters including
   lifecycle and fleets.

6. **📞 Flux alerts and notifies**: Flux provides health assessments,
   alerting to external systems and external events handling. Just
   "git push", and get notified on Slack and [other chat
   systems](https://github.com/fluxcd/notification-controller/blob/main/docs/spec/v1beta1/provider.md).

7. **💖 Flux has a lovely community that is very easy to
   work with!** We welcome contributors of any kind. The components of
   Flux are on Kubernetes core controller-runtime, so anyone can
   contribute and its functionality can be extended very easily.

## New releases in the Flux family

### Flux 0.16 hits the streets

We\'ve released flux2 v0.16.0. Starting with this version, all Flux APIs
are considered stable and ready for production use. :sparkles:

The highlights are:

- :rocket: The image automation APIs have been
  promoted from v1alpha2 to v1beta1. There are no breaking changes; to
  upgrade from `image.toolkit.fluxcd.io/v1alpha2`, simply change the
  API version to v1beta1 for all the image manifests in Git.

- :mechanical_arm: Flux has full support for mixed-arch
  Kubernetes clusters. We now run the conformance test suite for Flux
  pre-releases on both AMD64 and ARM64.

- :mag_right: New `flux trace` command that allows Flux
  users to point the CLI to a Kubernetes object in-cluster and get a
  detailed report about the GitOps pipeline that manages that particular
  object.

    ```cli
    $ flux trace podinfo-5dcdc87bc5-9pcrh --kind=pod \
    --api-version=v1 --namespace=podinfo
    Object:         pod/podinfo-5dcdc87bc5-9pcrh
    Namespace:      podinfo
    Status:         Managed by Flux
    ---
    HelmRelease:    podinfo
    Namespace:      podinfo
    Revision:       6.0.0
    Status:         Last reconciled at 2021-06-24 08:37:55 +0300 EEST
    Message:        Release reconciliation succeeded
    ---
    HelmChart:      podinfo-podinfo
    Namespace:      flux-system
    Chart:          podinfo
    Version:        >=1.0.0-alpha
    Revision:       6.0.0
    Status:         Last reconciled at 2021-06-24 08:31:40 +0300 EEST
    Message:        Fetched revision: 6.0.0
    ---
    HelmRepository: podinfo
    Namespace:      flux-system
    URL:            https://stefanprodan.github.io/podinfo
    Revision:       8411f23d07d3701f0e96e7d9e503b7936d7e1d56
    Status:         Last reconciled at 2021-06-24 07:57:22 +0300 EEST
    Message:        Fetched revision: 8411f23d07d3701f0e96e7d9e503b7936d7e1d56
    ```

:notebook_with_decorative_cover: Check out the [Flux roadmap](/roadmap/) updates.

### ⚠ Breaking Changes in 0.15

In this version, Flux and its controllers have been upgraded to
Kustomize v4. While Kustomize v4 comes with many improvements and bug
fixes, it introduces a couple of breaking changes:

- YAML anchors are no longer supported in Kustomize v4, see
  [kustomize/issues/3675](https://github.com/kubernetes-sigs/kustomize/issues/3675)
  for more details.
- Due to the removal of `hashicorp/go-getter` from Kustomize v4, the set
  of URLs accepted by Kustomize in the resources filed is reduced to
  file system paths, URLs to plain YAMLs and values compatible with
  git clone. This means you can no longer use resources from
  archives (zip, tgz, etc).
- Due to a
  [bug](https://github.com/kubernetes-sigs/kustomize/issues/3446)
  in Kustomize v4, if you have **non-string keys** in your
  manifests, the controller will fail with json: unsupported type
  error.

More details on breaking changes can be found at
[\#1522](https://github.com/fluxcd/flux2/issues/1522)

### Flagger 1.12 got released

1.12.1: This release comes with a fix to Flagger when used with Flux v2.

- Improvements: Update Go to v1.16 and Kubernetes packages to v1.21.1
  [\#940](https://github.com/fluxcd/flagger/pull/940)
- Fixes: Remove the GitOps Toolkit metadata from generated objects
  [\#939](https://github.com/fluxcd/flagger/pull/939)

1.12.0: This release comes with support for disabling the SSL
certificate verification for the Prometheus and Graphite metric
providers.

- Improvements:
  - Add insecureSkipVerify option for Prometheus and Graphite
    [\#935](https://github.com/fluxcd/flagger/pull/935)
  - Copy labels from Gloo upstreams
    [\#932](https://github.com/fluxcd/flagger/pull/932)
  - Improve language and correct typos in FAQs docs
    [\#925](https://github.com/fluxcd/flagger/pull/925)
  - Remove Flux GC markers from generated objects
    [\#936](https://github.com/fluxcd/flagger/pull/936)
- Fixes: Require SMI TrafficSplit Service and Weight
    [\#878](https://github.com/fluxcd/flagger/pull/878)

## Upcoming events

It's important to us to keep you up to date with new features and
developments in Flux and provide simple ways to see our work in action
and chat with our engineers.

### The Bug Scrub

Kingdon Barrett organised our first ever [Bug
Scrub](/blog/2021/06/flux-bug-scrub-announce/).
To quote from the announcement:

> For us, a great way to get started, is to learn more about Flux
> through direct experience, when e.g. trying to reproduce issues
> reported by other Flux users, and the general business of chopping
> wood and carrying water. The **Flux Bug Scrub** is born.

The inaugural first Bug Scrub event commenced and concluded on June 30.
It was a great success where we collectively as a team visited 53 issues
in about 60 minutes. This was a terrific opportunity which we will be
repeating on a regular weekly basis for the time being.

Kingdon will continue hosting these hour-long gatherings on a staggered
weekly basis, in the empty time slot which is opposite the existing
"CNCF Flux Project Meeting" community meeting; the next Bug Scrub is on
July 8 at 8:00 Pacific / 11:00 Eastern Time / 15:00 UTC, (and from now
on you can find them on the [CNCF Flux
calendar](https://lists.cncf.io/g/cncf-flux-dev/calendar).)
Volunteers at any skill level are welcome to attend, come spend an hour
levelling up your Flux knowledge by reviewing open issues with the team.

Watch this space and our social channels for news and more details about
these events as they happen. Also reach out to Kingdon if you want to
get involved in any bug scrubbing.

Check out [our calendar section](/#calendar) for more upcoming
and [links to recordings](/resources) of past talks.

## In other news

### People writing about Flux

#### (Typical) journey towards full GitOps

This is a new section where we want to highlight people who talk and
write about Flux. If you have an article you would like us to refer to,
hit us up on Slack or Twitter or Email. We're looking forward to giving
you a shout-out!

Alexander Holbreich wrote a very nice article called "[(Typical)
journey towards full
GitOps](https://alexander.holbreich.org/gitops-journey/)".

![Alexander Holbreich article](https://alexander.holbreich.org/images/headers/container-ship.jpg)

It's well-written, easy to read and goes into enough detail for
newcomers to understand it. Thanks Alexander for this write-up!

#### Flux at the Okteto Community Call

<https://okteto.com/blog/june-2021-community-call-recap/>

One of the Flux maintainers, [\@kingdonb](https://github.com/kingdonb),
was invited on the Okteto community call for show-and-tell about how
Flux and Okteto integration works; the video link is in the blog post
which is featured on the Okteto blog at the link above. See how the
Okteto CLI can be used to invoke a debugger inside a pod running on
your dev cluster, which together with VS Code shortens the inner loop
of development, providing a unique developer experience with Flux.

### Website and Docs news

Our web and docs team has been busy as well.

🤹 First of all we would like to congratulate everyone who added
themselves to the [Flux Adopters page](/adopters/). It's
beautiful for all of us who work on the Flux to see how our projects are
used in the wild.

📔 We moved our legacy documentation (Flux Legacy and Helm Operator) from
`docs.fluxcd.io` to `fluxcd.io/legacy` and replaced all old docs with
redirects. This was done because our docs were hosted on two different
pieces of infrastructure and came from different repositories. They were
hard to update and some of our users got confused about which docs they
were looking at. If you have any feedback about this, let us know.

🔋 We also just added a [Flux Integrations
page](/integrations/). If your extension
or integration is not listed yet, please add yourself. We will make this
page shine more in the future - we are also happy to work on joint blog
posts, etc. Just come and talk to us!

💖 Our landing page received a number of style updates and now shows Flux
contributors! It's great to be able to see everyone who is making this
happen.

![Contributors section](contributors-section-featured.png)

Many docs have received updates and more information and we are pleased
that many new docs PRs have been coming in from new contributors! We now
check links automatically as well.

## Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev
   meetings](/community/#meetings) on
   2021-07-01 15:00 UTC, or 2021-07-07, 12:00 UTC.
- Talk to us in the \#flux channel on [CNCF
   Slack](https://slack.cncf.io/)
- Join the [planning
   discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux v2, take a look at our [Get
   Started guide](/flux/get-started/)
   and give us feedback
- Social media: Follow [Flux on
   Twitter](https://twitter.com/fluxcd), join the
   discussion in the [Flux LinkedIn
   group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
