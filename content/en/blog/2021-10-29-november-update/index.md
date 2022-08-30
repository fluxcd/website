---
author: dholbach
date: 2021-10-29 20:30:00+00:00
title: November 2021 update
description: New releases in the Flux family (Server-Side Apply in Flux, Flagger 1.15). Max Jonas Werner (D2IQ) and Soulé Ba + Sunny (Weaveworks) are new Flux maintainers, lots of event news, Flux and OpenShift and much much more!
url: /blog/2021/11/november-2021-update/
resources:
- src: "**.png"
  title: "Image #:counter"
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read [last month's update
here](/blog/2021/10/october-2021-update/).

Let's recap what happened in October - there has been so much happening!

## News in the Flux family

### Server side apply has landed

We gave you a [heads-up on our
blog](/blog/2021/09/server-side-reconciliation-is-coming/)
a few weeks ago. Since then, it has happened: Server-Side Apply has
landed in Flux for real. This makes Flux more performant, your cluster
will get more observable and this opens up the gates for new features.
It also makes Flux more easily maintainable in the future.

Please refer to the announcement blog post to learn how to update your
cluster to work well with it!

### Flux 0.20 is out

Since the last monthly update a flurry of Flux releases saw the light of
day, so let's go through them one by one to see which new features,
fixes and improvements came our way.

0.20 adds a new command called flux tree. Here is what it can look like
in action:

```cli
$ flux tree kustomization flux-system --compact

Kustomization/flux-system/flux-system
├── Kustomization/flux-system/infrastructure
│ ├── HelmRepository/cert-manager/cert-manager
│ └── HelmRelease/cert-manager/cert-manager
├── Alert/flux-system/slack
├── Provider/flux-system/slack
└── GitRepository/flux-system/flux-system
```

On top of that we improved end-to-end tests and Git implementations
(more efficient shallow clones and performance fixes). Also note the new
support for [Sprig
functions](https://github.com/fluxcd/image-automation-controller/blob/v0.16.0/docs/spec/v1beta1/imageupdateautomations.md#commit-message-with-template-functions).

0.19 brought a bunch of new features: support for SOPS encrypted .env
files. We updated to Helm 3.7.1, added support for Prometheus
Alertmanager and experimental support for automatically getting
credentials from AWS when scanning images in ECR. On top of that
authentication enhancements for GCP and lots and lots of other
improvements and fixes.

0.18 brought Server Side Apply and more.

It's really really worth updating, but do note: If you are upgrading
from 0.17 or older versions, please see the [Upgrade Flux to the
v1beta2
API](https://github.com/fluxcd/flux2/discussions/1916)
guide.

### Flagger 1.15 is out

We are blessed and fortunate to have our own progressive delivery
solution within the Flux project. Its 1.15 release brings support for
NGINX ingress canary metrics (you will need nginx-ingress v1.0.2 at
least).

Starting with this version, Flagger will use the
spec.service.apex.annotations to annotate the generated apex
VirtualService, TrafficSplit or HTTPProxy.

Apart from that we updated the load tester binaries and added podLabels
to the load tester Helm chart.

### Flux on OpenShift progress

If you have been watching the OpenShift GitOps space, you will have seen
quite a bit of movement lately. We talked about this in some of our last
posts, we got [OpenShift docs up for
Flux](/flux/use-cases/openshift/), the
Flux Operator has landed in the OperatorHub and RedHat were key
presenters at the the last GitOps One-Stop Shop Event (see below).

Flux contributor and Developer Experience engineer at Weaveworks Chanwit
Kaewkasi has been hard at work and put together these proof-of-concept
repositories:

- [Multi-tenant demo for Flux on
  OpenShift](https://github.com/openshift-fluxv2-poc/platform-team):
  It is a Flux multi-tenancy demo for OpenShift. What's nice about
  the demo is that it will use only the Web UI of OpenShift to
  install Flux and bootstrap the demo. Yes - as a Cluster-Admin
  user, you can run a GitOps system by just clicking. You click to
  install Flux via OperatorHub, then you click to import one of the
  following snippets into your cluster, and your multi-tenant GitOps
  system will be ready to use in minutes.

- [An example of how to write Flux policies for
  Gatekeeper](https://github.com/openshift-fluxv2-poc/mt-flux-policy):
  this is a Rego-based OPA policy to support Flux multi-tenancy
  enforcement. Tested on OpenShift 4.8.

We are very pleased to see this relationship thriving - stay tuned for
more news!

### New maintainers on board the Flux project

We as the Flux community are blessed to have new contributors who step
up to become maintainers eventually. In the past month we had three(!)
new maintainers come on board.

#### Max Jonas Werner from D2IQ

Having been part of the Flux journey for a long while already, we knew
Max from the [Flux Dev
meetings](/community/#meetings) already.
When we learned that [D2IQ was basing their
product](https://d2iq.com/blog/goodbye-dispatch-hello-fluxcd)
on top of Flux, we were obviously thrilled. Now he is maintainer of
Flux - what's more: Max has contributed patches, review time and community
gardening time since then - and spoke at the [GitOps One-Stop Shop
Event](https://www.gitopsdays.com/) as well. Thanks for
everything you do! 💖

> "I\'m very happy to be joining a lively community and an extremely
> exciting project as a maintainer. Thank you for the warm welcome."

{{< imgproc max-jonas-werner Resize 500x >}}
Max Jonas Werner
{{< /imgproc >}}

#### Sunny and Soulé Ba from Weaveworks

[Sunny](https://github.com/darkowlzz) has been maintaining
(among many other things) tools like Weave Ignite for a while already,
and joined the Flux effort a few months back and since then made a big
number of improvements to almost all the Flux controllers. We are glad
to have him around - big parts of the recently started refactoring
effort will happen a lot faster!

[Soulé Ba](https://github.com/souleb), who also works for
Weaveworks, has been working on one big feature recently which was to
add Bitbucket Server (a.k.a Stash) support to Flux (via
[go-git-providers](https://github.com/fluxcd/go-git-providers)).
We are very pleased to have a solid team of people working on
go-git-providers and to be able to offer more providers. Thanks in any
case, Soulé for stepping up!

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Flux at GitOpsCon and KubeCon

#### GitOpsCon

We are proud and happy to have Flux Maintainer Scott Rigby co-host
GitOpsCon again, and see and hear all the great talks that featured
Flux! If you missed any of the talks, you can see the [schedule
here](https://events.linuxfoundation.org/gitopscon-north-america/program/schedule/)
and be on the lookout for the videos as they should be posted soon.

#### KubeCon

This was our first time hosting a hybrid booth - we were in-person and
online at KubeCon NA 2021 and were super happy to chat with all the
booth visitors and hear great talks from the community. Our [online
booth schedule](https://bit.ly/flux_kubecon21_schedule) is
still up - we'll update with video links as soon as they\'re available -
stay tuned! 📺🍿

Special shoutout to our Flux Maintainers Michael Bridgen and Hidde
Beydals for presenting Flux's Roadmap to GA, as well as Stefan Prodan,
Philip Laine, and Kingdon Barrett for more presentations at the Flux
Project Office Hours sessions! These will be part of the forthcoming
videos!

### GitOps One-Stop Shop Event

![GitOps One-Stop Shop Event](featured-image.jpg)

This was a half day event on October 20, 2021 to celebrate a major
milestone for our project! Speakers from top cloud and GitOps vendors -
**Amazon Web Services**, **D2iQ**, **Microsoft**, **VMware**, **Red
Hat**, and **Weaveworks** showcased their enterprise-grade GitOps
offerings which are all using Flux to provide the very best GitOps to
their customers!

If you missed it, no worries! You can still [sign up at the website
(www.gitopsdays.com) to watch](https://www.gitopsdays.com/)
the recording!

There were other Flux related talks this past month too -- keep an eye
out for these on the [Flux website resources
page](/resources/)!

### Flux Bug Scrub

Here is an update from Kingdon and the rest of the Flux team:

> We've had a great many special events in the past month or so, and our
> team has been busy coordinating, planning, participating, and promoting
> those, so meanwhile the Bug Scrub activity has been mostly on hiatus for
> the month of October! But we'll be starting up again in earnest, in the
> first week of November, and should begin holding Bug Scrub activities
> again regularly over the next few weeks, until the holiday season is
> upon us.
>
> If you are interested in making contributions to Flux but maybe aren't
> sure where to start, or just want to spend some time mulling over issues
> with the team, Bug Scrub is a great place to get acquainted with the
> issues that are being raised by community members and find out more
> about how you can play a part and help move the Flux project closer to
> graduation!
>
> You can find a link to the Bug Scrub [on our
> calendar](/#calendar), which has the Zoom
> link and is in UTC time, or get reminded in your own time zone by
> [subscribing to the flux-dev
> calendar](/community/#subscribing-to-the-flux-dev-calendar).
>
> Hope to see you there!

#### One more thing

We had quite a bit of OpenShift related news, [check out this
interview](https://twitter.com/RedHat/status/1453353304101203977)
between Stefan Prodan, one of our Flux maintainers and Chris Wright, the
Red Hat CTO. They cover GitOps from various interesting angles. It's
certainly worth your time.

{{< tweet user=RedHat id=1453353304101203977 >}}

## In other news

### News from the Website and our Docs

In the Flux team we are very happy we are able to put effort and time
into our documentation and website. This month we improved some of the
maintenance bits of the site, we updated to a new version of the Docsy
theme - which gives us more options for expressing ourselves in
documentation. A couple new adopters added themselves - welcome to our
community! Also thanks Juozas Gaigalas for the many fixes regarding
styling, beautification and bringing in a nicer 404 page! 🤩

On top of that: more frequently asked questions and many more updates to
the docs, particularly around the new world order involving Server-Side
Apply! We updated [our Contributor
docs](/contributing/) as well! Hope to see
you on the other side!

## Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  2021-11-04 or 2021-11-10.
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
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.

### Flux Project Facts

We are very proud of what we put together, here we want to reiterate
some Flux facts - they are sort of our mission statement with Flux.

1. 🤝 Flux provides GitOps for both apps or
  infrastructure. Flux and Flagger deploy apps with
  canaries, feature flags, and A/B rollouts. Flux can also manage
  any Kubernetes resource. Infrastructure and workload dependency
  management is built-in.
1. 🤖 Just push to Git and Flux does the rest. Flux
  enables application deployment (CD) and (with the help of Flagger)
  progressive delivery (PD) through automatic reconciliation. Flux
  can even push back to Git for you with automated container image
  updates to Git (image scanning and patching).
1. 🔩 Flux works with your existing tools: Flux works with
  your Git providers (GitHub, GitLab, Bitbucket, can even use
  s3-compatible buckets as a source), all major container
  registries, and all CI workflow providers.
1. ☸️ Flux works with any Kubernetes and all common Kubernetes
  tooling: Kustomize, Helm, RBAC, and policy-driven
  validation (OPA, Kyverno, admission controllers) so it simply
  falls into place.
1. 🤹 Flux does Multi-Tenancy (and "Multi-everything"):
  Flux uses true Kubernetes RBAC via impersonation and supports
  multiple Git repositories. Multi-cluster infrastructure and apps
  work out of the box with Cluster API: Flux can use one Kubernetes
  cluster to manage apps in either the same or other clusters, spin
  up additional clusters themselves, and manage clusters including
  lifecycle and fleets.
1. 📞 Flux alerts and notifies: Flux provides health
  assessments, alerting to external systems and external events
  handling. Just "git push", and get notified on Slack and [other
  chat
  systems](https://github.com/fluxcd/notification-controller/blob/main/docs/spec/v1beta1/provider.md).
1. 👍 Users trust Flux: Flux is a CNCF Incubating project
  and was categorised as \"Adopt\" on the [CNCF CI/CD Tech
  Radar](https://radar.cncf.io/2020-06-continuous-delivery)
  (alongside Helm).
1. 💖 Flux has a lovely community that is very easy to work
  with! We welcome contributors of any kind. The
  components of Flux are on Kubernetes core controller-runtime, so
  anyone can contribute and its functionality can be extended very
  easily.
