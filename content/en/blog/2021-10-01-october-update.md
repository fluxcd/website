---
author: dholbach
date: 2021-10-01 8:30:00+00:00
title: October 2021 update
description: Server-side reconciliation is coming, better transport and crypto support for libgit2, Flagger 1.14, KubeCon updates, GitOps One-Stop Shop Event to show-case Flux integrated being used in big GitOps offerings, community news!
url: /blog/2021/10/october-2021-update/
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read [last month's update
here](/blog/2021/09/september-2021-update/).

Let's recap what happened in September - there has been so much
happening!

### Flux Project Facts

We are very proud of what we put together, here we want to reiterate
some Flux facts - they are sort of our mission statement with Flux.

1. 🤝 **Flux provides GitOps for both apps or
  infrastructure**. Flux and Flagger deploy apps with
  canaries, feature flags, and A/B rollouts. Flux can also manage
  any Kubernetes resource. Infrastructure and workload dependency
  management is built-in.
1. 🤖 **Just push to Git and Flux does the rest**. Flux
  enables application deployment (CD) and (with the help of Flagger)
  progressive delivery (PD) through automatic reconciliation. Flux
  can even push back to Git for you with automated container image
  updates to Git (image scanning and patching).
1. 🔩 **Flux works with your existing tools**: Flux works with
  your Git providers (GitHub, GitLab, Bitbucket, can even use
  s3-compatible buckets as a source), all major container
  registries, and all CI workflow providers.
1. ☸️ **Flux works with any Kubernetes and all common Kubernetes
  tooling**: Kustomize, Helm, RBAC, and policy-driven
  validation (OPA, Kyverno, admission controllers) so it simply
  falls into place.
1. 🤹 **Flux does Multi-Tenancy (and "Multi-everything")**:
  Flux uses true Kubernetes RBAC via impersonation and supports
  multiple Git repositories. Multi-cluster infrastructure and apps
  work out of the box with Cluster API: Flux can use one Kubernetes
  cluster to manage apps in either the same or other clusters, spin
  up additional clusters themselves, and manage clusters including
  lifecycle and fleets.
1. 📞 **Flux alerts and notifies**: Flux provides health
  assessments, alerting to external systems and external events
  handling. Just "git push", and get notified on Slack and [other
  chat
  systems](https://github.com/fluxcd/notification-controller/blob/main/docs/spec/v1beta1/provider.md).
1. 👍 **Users trust Flux**: Flux is a CNCF Incubating project
  and was categorised as \"Adopt\" on the [CNCF CI/CD Tech
  Radar](https://radar.cncf.io/2020-06-continuous-delivery)
  (alongside Helm).
1. 💖 **Flux has a lovely community that is very easy to work
  with!** We welcome contributors of any kind. The
  components of Flux are on Kubernetes core controller-runtime, so
  anyone can contribute and its functionality can be extended very
  easily.

This section has made it onto the landing page of
<https://fluxcd.io> now - let us know how you like it!

## News in the Flux family

### Server-side reconciliation is coming

We are going to land a big feature with lots of improvements for
everyone very soon. Server-side reconciliation will make Flux more
performant, improve overall observability and going forward will allow
us to add new capabilities, like being able to preview local changes to
manifests without pushing to upstream.

⚠ **Changes required**: Due to a [Kubernetes
issue](https://github.com/kubernetes/kubernetes/pull/91748),
we require a certain set of Kubernetes releases (starting 1.6.11 - more
on this below) as a minimum. The logs, events and alerts that report
Kubernetes namespaced object changes are now using the
Kind/Namespace/Name format instead of Kind/Name.

Read our [detailed release
announcement](/blog/2021/09/server-side-reconciliation-is-coming/)
with instructions on how to prepare for this change.

### Better transport and crypto support for libgit2

The next release of Flux is coming soon and will include an improvement
to the `libgit2` Git implementation. The `source-controller` and
`image-automation-controller` both use [this
library](https://github.com/libgit2/libgit2) (in combination with others
like [go-git](https://github.com/go-git/go-git)) to perform cloning and/or push
operations on remote Git repositories.

Unfortunately, due to `libgit2` depending on various other C libraries
for transport and crypto, using the OS packages has proven to not always
provide a reliable setup, especially not one that supports a wide range
of key formats. As we want our users to be able to use modern private
and/or host key formats like ECDSA* and ED25519, we now build the library
ourselves while linking against the correct libraries (OpenSSL and LibSSH2)
which should solve most issues around private keys. Support for a wider
range of host keys is still pending, but will eventually become available
as well, once `libgit >=1.2` can properly be used in Go.

This will also prepare us for changing the build to static, which will allow
us to enable fuzzing for more controllers.

Check out [the in-flight
PR](https://github.com/fluxcd/source-controller/pull/437)
for more information if you are curious. Thanks a lot Chanwit Kaekwasi, Hidde
Beydals and Sunny for your work on this!

### Flagger 1.14 has landed

We have released Flagger v1.14.0. This release comes with bug fixes to
Istio load balancer settings and in-line PromQL. Starting with this
version, the canary analysis can be extended with metrics targeting
InfluxDB, Dynatrace, and Google Cloud Monitoring (Stackdriver).

Thanks to Somtochi Onyekwere for integrating Flagger with InfluxDB &
Stackdriver and for all the bug fixes.

## Upcoming events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Flux at GitOpsCon and KubeCon

One of the really big themes at KubeCon this time is GitOps. Because of
this, KubeCon organisers have put together GitOpsCon as well, as a
dedicated Day 0 event. Below we are going to list our favourites Flux
related sessions - for an up-to-date list of everything take a look at
the "schedule" of [our Flux KubeCon
mini-site](https://bit.ly/kubecon21_flux). *(All times are
Pacific Time.)*

#### Meet the Maintainer

There will be three Flux Project Office Hours where you can meet our
maintainers:

- [Oct 12 10am: Stefan
  Prodan](https://community.cncf.io/events/details/cncf-cncf-project-office-hours-presents-flux-project-office-hour-1000-1045-am-pst/)

- [Oct 13 4:30pm: Kingdon
  Barrett](https://community.cncf.io/e/mw8bz6/)

- [Oct 14 11:30am: Philip Laine](https://sched.co/mwOi)

#### GitOpsCon

Our friends from the GitOps working group have put together a fantastic
event - here are some talks you should watch out for on October 12:

- 9:20am: Ricardo Rocha, CERN: [A Multi-Cluster, Multi-Cloud
  Infrastructure with GitOps at
  CERN](https://sched.co/mzxk)

- 9:50am: Ayush Ghosh & Sergey Sergeev, Cisto Sytems: [GitOpsify
  Cellular Architecture](https://sched.co/mzyT)

- 12:45pm: Adrian Vacaru, Fidelity Investments: [Managing Apps
  Dependencies and Kubernetes Versions with Kraan and
  Flux](https://sched.co/mzy5)

- 1:15pm: Uma Mukkara, Chaos Native: [Using GitOps for Kubernetes
  Reliability at Scale](https://sched.co/mzy8)

- 2:55pm: Mae Large & Priyanka Ravi, State Farm: [A Day in the Life
  of the GitOps Platform Team](https://sched.co/mzy8)

- 4:20pm: Leigh Capili, VMware: [Building Flux's Multi-Tenant API
  with K8s User Impersonation](https://sched.co/mzyE)

#### KubeCon talks on the main event and our booth

Take a look at our [Flux KubeCon
mini-site](https://bit.ly/kubecon21_flux). This is where
you can connect with us for all the Flux related talks at the event.
During KubeCon hours we will be at our virtual and in-person booth in
the CNCF Project Pavillion - drop by for a chat, for short talks from
engineers and users. It'll be a great way to get involved with our
community and have all your questions answered.

### GitOps One-Stop Shop Event

So KubeCon will be lots of fun and give you lots of great Flux content,
but only a week afterwards we have a real treat coming up for you.

If you want to learn more about how big vendors have built their GitOps
offerings on top of Flux, sign up at
[https://gitopsdays.com](https://gitopsdays.com) and learn
from Amazon, D2IQ, Microsoft, VMware and Weaveworks why they chose Flux
and which cool services and products they have got to offer. See you
there on October 20th!

### Flux Bug Scrub

During KubeCon, Flux's weekly Bug Scrub will be postponed unless another
volunteer wants to run one! Kingdon, who hosts Bug Scrub each week, is
going in person to Los Angeles to present: [how to deploy Jenkins
declaratively with Helm Controller](https://sched.co/lV0V),
and other fun things.

Throughout KubeCon, look for Flux maintainers at media events and giving
talks in the Flux booth, (TBD: or at least, virtually talking in the
booth! Maybe due to social distancing rules.)

As for Bug Scrub, I foresee that cancellation or postponement of the
weekly event is likely while KubeCon is going on in person, ... but if
there are volunteers at the usual time, and enough interested people who
want to perform the bug scrub activity get together, they will be put to
work! There will always be plenty of bugs to scrub for the foreseeable
future.

This week, and every other week, find Bug Scrub with a link to the Zoom
invite [beneath the fold](/#calendar)
alongside other scheduled Flux developer team events.

### One more thing

Martin Hickey (Helm maintainer), and Scott Rigby (Helm and Flux
maintainer) present a feature showcase and demos of both Helm and Flux,
reasons for the overwhelming community use of Helm for application
packaging and deployment on k8s, and how Helm is extended by Flux for
teams moving to GitOps.

> 🔹 Helm - <https://helm.sh/> helps
> you manage Kubernetes applications --- Helm Charts helps you define,
> install, and upgrade even the most complex Kubernetes application.
>
> 🔹[The GitOps Toolkit](/flux/components)
> is the set of APIs and controllers that make up the runtime for Flux.
> The APIs comprise Kubernetes custom resources, which can be created
> and updated by a cluster user, or by other automation tooling.
>
> 🔹[The Helm Controller](/flux/components/helm/)
> built on Kubernetes controller runtime and is part of the GitOps
> Toolkit -- allows one to declaratively manage Helm chart releases with
> Kubernetes manifests.

📍 Date: [Tuesday, October 5th @ 10 am PST to 11 am
PST](https://www.meetup.com/cloudnativescale/events/280568379/)
(1:00 pm EST - 2:00 pm EST)

## In other news

### News from the Website and our Docs

Our website <https://fluxcd.io> is the central place for news and docs
regarding Flux and we put quite some effort into making it ever more useful
and interesting. If you have feedback or would like to help out, reach out
`alisondy`, `dholbach` or `scottrigby` on Slack.

In the past month we made large parts of the site more easily maintainable.
Juozas Gaigalas simplified the styling and beautified the looks of the site
in many places as well - thanks for your work on it!

We are pleased to see that the number of contributors to the docs is slowly
growing. Many small improvements to make the content more readable and
correct. Go team!

Apart from that we were able to add more [adopters](/adopters) and
[integrations](/integrations). Please add yourself if you haven't already.

What to watch out next for: Alison Dowdney is working on restructuring the
documentation to make it even easier to find things. Reach out to her, if you
want to help out or have observations you would like to share.

### People writing about Flux

We have two sets of articles we would like to share. (Please reach out to
us if you find others show-casing Flux projects.)

#### Manage your Kubernetes clusters with Flux 2

Cyril Becker wrote a very nice introductory article over at
<https://medium.com/alterway/manage-your-kubernetes-clusters-with-flux2-82dd1cfe2a6a>.
If you are entirely new to the concept of GitOps and want to learn more
and follow a how-to, check the article out.

#### GitOps - Part 1+2

Girish Goudar, Cloud & DevOps Architect at EY wrote a set of two articles to
explain GitOps using Flux.

In the first article <https://www.linkedin.com/pulse/gitops-part-1-girish-goudar-1c/>
you will learn how to deploy apps using Helm and Kustomizations.

The second article <https://www.linkedin.com/pulse/gitops-part-2-girish-goudar/>
focuses on securing apps using Mozilla SOPS.

## Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev
  meetings](/community/#meetings) on
  2021-10-07 15:00 UTC, or 2021-10-21, 15:00 UTC.
- Talk to us in the \#flux channel on [CNCF
  Slack](https://slack.cncf.io/)

- Join the [planning
  discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/)
  and give us feedback
- Social media: Follow [Flux on
  Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/)

We are looking forward to working with you.
