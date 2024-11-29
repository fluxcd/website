---
author: dholbach
date: 2021-03-31 08:30:00+00:00
title: April 2021 update
description: The Cloud Native Computing Foundation promoted Flux to Incubation status. Flux2 reaches 0.11 milestone, new Flagger release, upcoming events and general community news!
url: /blog/2021/03/april-2021-update/
tags: [monthly-update]
---

## Before we get started, what is GitOps?

If you are new to the community and GitOps, you might want to check out
some general resources. We like [GitOps
manifesto](https://web.archive.org/web/20231124194854/https://www.weave.works/blog/what-is-gitops-really)
or the [official GitOps
FAQ](https://web.archive.org/web/20231206152723/https://www.weave.works/blog/the-official-gitops-faq)
written by folks at Weaveworks.

## The Road to Flux v2

The Flux community has set itself very ambitious goals for version 2 and
as it's a multi-month project, we strive to inform you each month about
what has already landed, new possibilities which are available for
integration and where you can get involved. Read [last month's update
here](/blog/2021/03/march-2021-update/).

Let's recap what happened in April - there have been many changes.

We made huge strides moving Flux 2 forward. The end i.e. calling Flux 2
a GA release is slowly getting in sight and we have a huge list of
contributors from all around the world to thank for this!

First we released Flux2 `0.9.1` which came with improvements to the
notification system. The kustomize-controller and helm-controller are
now performing retries with exponential backoff when fetching artifacts.
This prevents spamming events and alerts when source-controller becomes
unavailable for a short period of time (e.g. upgrades, pod rescheduling,
leader election changes, etc).

Much bigger and more substantial was the release of `0.10`, which
saw these changes:

- We added new commands to improve troubleshooting: `flux logs`, `flux
  get source all`, `flux get images all` (CLI)
- The logs command supports streaming and advanced filtering: e.g.
  `flux logs -f --level=error --kind=helmrelease
  --namespace=prod` (CLI)
- Push image updates to a different branch for manual approvals
  through pull requests (`image-automation-controller`)
- Commit message customisations: list updated images and manifests
  (`image-automation-controller`)
- Restrict image automation to a path relative to the Git repo root
  (`image-automation-controller`)
- Trigger image updates to Git using Azure Container Registry webhooks
  (`notification-controller`)
- Support for sending alerts to Google Chat (`notification-controller`)
- Flux Terraform Provider has been promoted from experimental to beta
  (terraform-provider-flux)

Hot on the heels of this was `0.11.0` and v0.1.1 of the Terraform module.
:notebook_with_decorative_cover: Highlights:

- Default leader election configuration has been improved to prevent the controllers from crashing when the Kubernetes API rate limits requests. This will be most notable to Azure users where the issue was observed a lot.
- In case the new defaults are not sufficient, the configuration can now be tweaked using flag arguments as well.
- `flux create secret git` and `flux create source git` now support supplying a private key from a file using `--private-key-file`.
- The `helm-controller` will now emit collected logs on release failures in the status conditions and as an event, this should make it much easier to debug wait timeout errors.
- SOPS in the `kustomize-controller` has been updated to v3.7.0, support for the newly added age encryption format is planned. :hourglass_flowing_sand:
- All controllers do now record the suspend status of resources in a gotk_suspend_status Prometheus gauge metric.

🚀 Check out [the guide on how to automate image updates to Git](/flux/guides/image-update/).

Next up we will triage `image-*` issues and mark upcoming changes for
v1alpha2. The proposal for v1alpha2 is under discussion at [https://github.com/fluxcd/flux2/discussions/1124](https://github.com/fluxcd/flux2/discussions/1124).

As the [go-git team](https://github.com/go-git) made some strides of
their own, we can finally [bootstrap GitHub/GitLab
on-prem](https://github.com/fluxcd/source-controller/pull/324)
with self-signed certs :tada:. They also fixed clones of git
sub-modules, so we should be able to unblock Flux 1 users who use
sub-modules instead of Kustomize remote git repositories.

## Flux is a CNCF Incubation project

![Flux in Incubation](/img/incubation.png)

You will likely have seen the news elsewhere already, but Flux was
promoted from CNCF Sandbox to CNCF Incubation. This is a huge step for
the validation of our work, direction, end-user uptake and maturity of
our project. Many of us worked hard to make this possible. It's not just
folks who write the code or documentation, but also everyone who gives
talks, works with organisations to implement Flux and GitOps, does
training, writes books, and countless other things. It was beautiful how
the Technical Oversight Committee and SIG App Delivery at CNCF all
acknowledged this and made it a special point to talk to some companies
who use Flux in production.

Here is a bit of a press round-up if you want to read more about the
history, the move itself and what it means:

- **[Our own announcement](/blog/2021/03/flux-is-a-cncf-incubation-project/)**
- CNCF:
  [https://www.cncf.io/blog/2021/03/11/cncf-toc-votes-to-move-flux-from-sandbox-to-incubation/](https://www.cncf.io/blog/2021/03/11/cncf-toc-votes-to-move-flux-from-sandbox-to-incubation/)
- CNCF On-Demand Webinar: Flux is Incubating + The Road Ahead:
  [https://www.cncf.io/webinars/cncf-on-demand-webinar-flux-is-incubating-the-road-ahead/](https://www.cncf.io/webinars/cncf-on-demand-webinar-flux-is-incubating-the-road-ahead/)
- Weaveworks blog:
  [https://www.weave.works/blog/flux-incubation](https://web.archive.org/web/20221226013915/https://www.weave.works/blog/flux-incubation)
- ZDNet:
  "While it\'s only just out of the incubator, Flux has already
  found many users. More than 80 organizations use it in production.
  This includes Fidelity Investments, Starbucks, and Plex Systems.
  The CNCF End User Community recommends Flux in its Adopt category
  of its Technology Radar on Continuous Delivery. Besides Helm, Flux
  is the only CD, the group recommends for adoption."  
  [https://www.zdnet.com/article/flux-gitops-program-becomes-a-cncf-incubator-program/](https://www.zdnet.com/article/flux-gitops-program-becomes-a-cncf-incubator-program/)
- The New Stack:
  [https://thenewstack.io/flux-takes-its-continuous-delivery-and-operations-to-cncf-incubation/](https://thenewstack.io/flux-takes-its-continuous-delivery-and-operations-to-cncf-incubation/)
- Container Journal:
  [https://containerjournal.com/features/cncf-advances-flux-cd-platform-for-kubernetes-environments/](https://containerjournal.com/features/cncf-advances-flux-cd-platform-for-kubernetes-environments/)

## Flagger v1.7.0 is out

This release comes with support for manually approving the traffic weight increase. Starting with this version, Flagger can be used with Linkerd v2.10 and its new Viz addon, please see [the updated guide](/flagger/tutorials/linkerd-progressive-delivery). Thanks to the Linkerd team for contributing to Flagger.

## Upcoming events

It's important to us to keep you up to date with new features and
developments in Flux and provide simple ways to see our work in action
and chat with our engineers. In the next days we have these events
coming up for you:

> **5 Apr 2021 - [Flux v2 on Azure with Leigh
> Capili](https://www.meetup.com/GitOps-Community/events/276674768/)**
>
> With Flux v2 we are building extensible and intuitive tools for
> implementing GitOps to fit your team\'s needs. Flux 2 integrates well
> with existing cloud services you may already be using whether it\'s
> for source control, secrets-management, or your Kubernetes clusters
> themselves.
>
> Join Leigh Capili, DX Engineer at Weaveworks, for a live-demo of Flux
> on Azure. Let\'s take Microsoft\'s cloud offerings for a spin.
>
> **19 Apr 2021 - [Setting up Notifications, Alerts, & Webhook with
> Flux v2 by Alison
> Dowdney](https://www.meetup.com/GitOps-Community/events/276582835/)**
>
> 🚨❗️ Notifications & Alerts ⚠️\
> When operating a cluster, different teams may wish to receive
> notifications about the status of their GitOps pipelines. For example,
> the on-call team would receive alerts about reconciliation failures in
> the cluster, while the dev team may wish to be alerted when a new
> version of an app was deployed and if the deployment is healthy.\
> \
> 🔄 Webhook Receivers 🔁\
> The GitOps toolkit controllers are by design pull-based. In order to
> notify the controllers about changes in Git or Helm repositories, you
> can setup webhooks and trigger a cluster reconciliation every time a
> source changes. Using webhook receivers, you can build push-based
> GitOps pipelines that react to external events.\
> \
> Join Alison Dowdney, Developer Experience Engineer at Weaveworks and
> CNCF Ambassador, as she walks through how to define a provider and an
> alert, git commit status, expose the webhook receiver, define a git
> repository and receiver.
>
> **29 Apr 2021 - [Doing GitOps for multicloud resource management
> using Crossplane and Flux2 (at Conf42: Cloud Native
> 2021)](https://www.conf42.com/Cloud_Native_2021_Leonardo_Murillo_gitops_multicloud_crossplane_flux2)**
>
> Leonardo Murillo - CTO @ Qwinix
>
> How would you like for resources to be automatically created across
> any clouds of your choosing by simply pushing a manifest to a
> repository? In this talk we\'ll see hands on how to do multi cloud
> management following the GitOps operating model by leveraging Flux2
> and Crossplane!
>
> A continuous delivery world without pipelines, with automatic
> reconciliation of resources eliminating all drift in configuration,
> everything versioned and everything declarative! *That is what GitOps
> is all about*. What if only you could follow this same operating
> model for all your cloud resources, across any public cloud?\
>
> *In this talk you\'ll learn how to do precisely that!* We will be
> using Flux2 and Crossplane, and you will see hands on how, using these
> two CNCF projects, you can manage your entire multicloud architecture
> using Kubernetes as your control plane while following the GitOps
> principles.
>
> You will learn to:
>
> - Install Flux2
> - Using Flux2, install Crossplane in your cluster
> - Configure AWS and GCP providers for Crossplane
> - Deploy resources across both clouds with nothing but a push to the
> repo
> \
> This talk is all about code! A couple of slides in the deck to give a
> brief intro of GitOps and the two projects we\'ll be using, and then
> it\'s all live code!
>
> **09-10 Jun 2021 -** [GitOps Days 2021](https://www.gitopsdays.com)
>
> The team behind GitOps Days is still busy putting the event together,
> and the Call for Papers is still open. So if you have something you'd
> like to talk about, head to the website and submit your talk!

Check out [our calendar section](/#calendar) for more upcoming
and [links to recordings](/resources) of past talks.

## In other news

💻 The Flux Community is looking for folks who are interested in helping
out with the website. We are working on subsuming all our docs on
<https://fluxcd.io>, moving to the Hugo Docsy theme. If you know your way
around fixing up CSS and/or want to help make docs and the website more
cohesive and inviting, please talk to \@dholbach or \@alisondy on Slack.

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  2012-04-08 15:00 UTC, or 2021-04-14, 12:00 UTC

- Talk to us in the \#flux channel on [CNCF
  Slack](https://slack.cncf.io/)

- Join the [planning
  discussions](https://github.com/fluxcd/flux2/discussions)

- And if you are completely new to Flux v2, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback

- Social media: Follow [Flux on
  Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
