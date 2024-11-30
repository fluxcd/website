---
author: dholbach
date: 2021-03-01 08:30:00+00:00
title: March 2021 Update
description: This month's edition of updates on Flux v2 developments - feature parity, 0.9 release, new Flagger logo, update on GA release, project and website changes, new events and more.
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
tags: [monthly-update]
---

## Before we get started, what is GitOps?

If you are new to the community and GitOps, you might want to check out
some general resources. We like the [GitOps
manifesto](https://web.archive.org/web/20231124194854/https://www.weave.works/blog/what-is-gitops-really) or the
[official GitOps FAQ](https://web.archive.org/web/20231206152723/https://www.weave.works/blog/the-official-gitops-faq)
written by folks at Weaveworks.

## The Road to Flux v2

The Flux community has set itself very ambitious goals for version 2 and
as it's a multi-month project, we strive to inform you each month about
what has already landed, new possibilities which are available for
integration and where you can get involved. Read last month's update
here: [February 2021 Update](/blog/2021/02/february-2021-update/).

Let's recap what happened in February - there have been many changes.

### Feature Parity - what is this?

If you have been following Slack and other resources you will have heard
that in the past Flux v2 releases we reached the "feature parity"
milestone, but what does that mean?

When we embarked on this journey to rewrite Flux from scratch, we set
out three big blocks of work:

1. support for Flux operations in read-only mode
1. Helm v3 support
1. Image update functionality

Once all of this was realised in Flux v2, we would have feature parity
between v1 and v2. After around 10 months of development, we have
achieved this.

So what's left to do? This does not mean Flux v2 is GA just yet. We are
in the process of finalising all APIs, updating our documentation and
generally consolidating everything. You can find more details on [our
roadmap](/roadmap/).

This means that we will spend some more time on stabilisation and we
need your help testing. Flux v2 is only a couple of weeks away and it
will be helpful to start your migration journey early. Refer [to this
discussion](https://github.com/fluxcd/flux2/discussions/413)
and [our upcoming
workshop](https://www.meetup.com/GitOps-Community/events/276539791/).

### Flux v2 is now up at 0.9

Last month saw two big releases of Flux v2.

0.8 included these highlights:

- Support for Helm post-renderer and Kustomize patches (`helm-controller`)
- Self-signed certs support for Git over HTTPS (`source-controller`)
- In-line Kustomize Strategic Merge and JSON 6902 patches (`kustomize-controller`)
- Basic templating with bash-style variable substitutions (`kustomize-controller`)
- Prevent objects like volumes from being garbage collected with labels (`kustomize-controller`)
- Filter events from alerting based on regular expressions (`notification-controller`)
- Support numerical ordering in image policies (`image-reflector-controller`)
- Support for Azure DevOps and other Git v2 providers (`image-automation-controller`)
- Install Flux on tainted Kubernetes nodes and other bootstrap improvements (CLI)
- Uninstall Flux by handling finalizers and preserving all the deployed workloads (CLI)

Hot on its heels 0.9 was released and included these new features:

- flux is now available for Apple Silicon (CLI)
- The manifests are embedded in the flux binary allowing air-gapped installations (CLI)
- Support for recreating Kubernetes objects (e.g. Jobs) when immutable fields are changed in Git (`kustomize-controller`)
- Fix alert regex filtering (`notification-controller`)
- Improved status reporting for Git push errors (`image-automation-controller`)

:boom: This version comes with breaking changes to Helm users due
to upstream changes in Helm v3.5.2. Charts not versioned using **strict
semver** can no longer be deployed using Flux due to this. When using
charts from Git, make sure that the version field is set to a valid
semver in Chart.yaml.

:rocket: The migration guides from Flux v1 to v2 can be found
here <https://github.com/fluxcd/flux2/discussions/413>.

Thanks a lot to everyone who contributed to these releases! 💖

## Upcoming events

It's important to us to keep you up to date with new features and
developments in Flux and provide simple ways to see our work in action
and chat with our engineers. In the next days we have these events
coming up for you:

8 Mar 2021 - [Migrating from Flux v1 to Flux v2 with Leigh
Capili](https://www.meetup.com/GitOps-Community/events/276539791/)

> Welcome to a GitOps Days Community Special!
>
> Get ahead of the game and migrate to Flux v2! With Flux v1 in
> maintenance mode we want to ensure you\'re ready for the transition to
> Flux v2.
>
> In this session, Leigh Capili, DX Engineer at Weaveworks, will demo
> the [Flux guide on how to Migrate from Flux v1](/flux/migration/flux-v1-migration/),
> including bootstrapping a cluster with Flux 1 and how to move it over
> to Flux v2.
>
> If we don\'t get to everything in this session, we will have
> subsequent sessions to cover this topic again. Join us we\'ll see how
> far we get!
>
> Resources:
>
> 📍 [Flux v2 Documentation](/flux/)
>
> 📍 [Flux v2 Guide Migrate from Flux v1](/flux/migration/flux-v1-migration/)
>
> 📍 [Flux v2 roadmap](/roadmap/).

Check out [our calendar section](/#calendar) for more upcoming
and [links to recordings](/resources) of past talks.

## In other news

**CNCF**: Flux is still in the process of [getting promoted to
Incubation status](https://github.com/cncf/toc/pull/567)
within the CNCF. This always takes a while. So far we cleared Due
Diligence during which our production users were interviewed, and the
two-week public comment period went successfully as well.

**Website**: The Flux Community team has put some more love into our
website <https://fluxcd.io/>, if you would like to join the team, have
ideas on how to make it better or would like to join the Comms team,
please reach out to `@dholbach` or `@staceypotter` on Slack.

**Flagger**: The [discussions around having a new logo for
Flagger](https://github.com/fluxcd/flux2/discussions/653)
have concluded; below is the winner. Thanks a lot [Bianca Cheng
Costanzo](https://github.com/bia) for working on this! Thanks
also everyone else for updating the diagrams, website and CNCF
Landscape.

![Flagger logo](flagger-stacked-color-featured.png)

**Meeting times**: the Flux team holds weekly, public meetings. To make
these accessible to everyone we offer an "early" and a "late" meeting to
make sure everyone can attend. Due to changes in the team we approved
the request to move the times a little, so we are currently following
this schedule:

- \"early\" meeting: Uneven weeks: Wed, 10:00 UTC
- \"late\" meeting: Even weeks: Thu, 15:00 UTC

Find all [the information about meetings here](/community/#meetings).

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings)
  on March, 3rd 12:00 UTC, or March 11th, 15:00 UTC
- Talk to us in the `#flux` channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux v2, take a look at our
  [Get Started guide](/flux/get-started/) and
  give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
