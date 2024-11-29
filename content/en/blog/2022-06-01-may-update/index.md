---
author: dholbach
date: 2022-06-01 12:30:00+00:00
title: May 2022 Update
description: "New Flux and Flagger releases - lots of new features. KubeCon Wrap-Up, GitOps Days coming up, Flux Ecosystem news, new project member and maintainer - and lots lots more!"
url: /blog/2022/06/may-update/
resources:
- src: "**.png"
  title: "Image #:counter"
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2022/05/april-2022-update/).

It's the beginning of June 2022 - let's recap together what happened in
May - it has been a lot!

## News in the Flux family

### Flux v0.30 release

The latest Flux release is the v0.30 release series. It comes with new
features and improvements. Users are encouraged to upgrade for the best
experience. Note:
[v0.29.0](https://github.com/fluxcd/flux2/releases/tag/v0.29.0)
included breaking changes.

:rocket: Features and improvements

- Support for disabling remote bases in Kustomize overlays: this
  release adds support to the `kustomize-controller` for disallowing
  remote bases in Kustomize overlays using `--no-remote-bases=true`
  (`default: false`). When this flag is enabled on the controller, all
  resources must refer to local files included in the Source
  Artifact, meaning only the Flux Sources can affect the
  cluster-state. Users are advised to enable it on production
  systems for security and performance reasons.
- Support for defining a `KubeConfig` Secret data key: both
  `Kustomization` and `HelmRelease` resources do now accept a
  `.spec.kubeConfig.SecretRef.key` definition. When the value is
  specified, the `KubeConfig` JSON is retrieved from this data key in
  the referred Secret, instead of the defaults (value or
  `value.yaml`).
- Support for defining a `ServiceAccountName` in `ImageRepository`
  objects: the `ImageRepository` object does now accept a
  `.spec.serviceAccountName` definition. When specified, the image
  pull secrets attached to the ServiceAccount are used to
  authenticate towards the registry.

:gift: [Link to release
page](https://github.com/fluxcd/flux2/releases/tag/v0.30.2)

### 🔒 Flux Security announcement

We published three CVEs today which affect Flux versions earlier than
v0.29.0. We recommend updating your Flux system at your earliest
convenience.

More information on the advisories can be found in our [security policy
page](https://github.com/fluxcd/flux2/security/policy#advisories).

To get some additional background on the advisories and what steps we
are taking to make Flux more secure, check out our [blog post about the
advisories](/blog/2022/05/may-2022-security-announcement/)
as well.

### Upcoming Flux Release

The next Flux release is just a few days out. Here is in a nutshell what you can look forward to - but there’ll be more!

- OCI Helm chart support as described in [RFC-0002](https://github.com/fluxcd/flux2/tree/main/rfcs/0002-helm-oci) will become available. But at time of writing, has two caveats:
  - Chart dependencies from OCI repositories are not supported. [#722](https://github.com/fluxcd/source-controller/issues/722)
  - Custom CA certificates are not supported. [#723](https://github.com/fluxcd/source-controller/issues/723)
- `GitRepository` reconciliation will be more efficient when checking out repositories using branches or tags by added support for no-op clones.
- The `libgit2` managed transport will be moved out of experimental mode, and is the new default.

Make sure you watch our Slack and Twitter to get the update. [Give us a star](https://github.com/fluxcd/flux2) and watch for releases maybe as well.

### Flagger 1.21.0 brings lots of improvements

[This release](https://github.com/fluxcd/flagger/releases/tag/v1.21.0)
comes with an option to disable cross-namespace references to Kubernetes
custom resources such as `AlertProviders` and `MetricProviders`. When
running Flagger on multi-tenant environments it is advised to set the
`-no-cross-namespace-refs=true` flag.

In addition, this version enables Flagger to target Istio and Kuma
multi-cluster setups. When installing Flagger with Helm, the service
mesh control plane `kubeconfig` secret can be specified using `--set
controlplane.kubeconfig.secretName`.

### Flux Ecosystem

We have a lot of updates from the Flux Ecosystem and love how everything
keeps on growing! If you are interested in more news from Flux
integration, make sure you register for [GitOps
Days](https://www.gitopsdays.com/) at 8-9 June - a lot of
engineers and companies will be talking about their work and how you can
benefit from it.

#### Flux Subsystem for Argo

[Flux Subsystem for Argo](https://github.com/flux-subsystem-argo/flamingo)
was upgraded to support Argo CD v2.2.9, and welcomed Kingdon Barrett as
a new maintainer for the project.

#### Terraform-controller

[terraform-controller](https://github.com/weaveworks/tf-controller) v0.9.5
was released which contains new features such as support for Runner Pod's
metadata, support environment variables for Runner Pod so that you can set
proxy for Terraform binary with `HTTPS_PROXY` for example. This release
also included many bug fixes.

#### Weave GitOps

The [Weave GitOps](https://github.com/weaveworks/weave-gitops) team released
v0.8.1 for Weave GitOps. This release is an iteration on top of our prior
release.  We have fixed a lot of bugs and made UI enhancements based on
feedback from the community. For example, you are able to reconcile Flux
objects directly from the UI. We have a lot of great features planned
over the next couple months. Please do not hesitate to drop in some
feature requests.

#### New additions to the Flux Ecosystem

We are thrilled to see the Flux Ecosystem growing on a continuous basis.
The most recent additions to our [Flux Ecosystem page](/ecosystem/) are
`flux-kluctl-controller` and `gardener-extension-shoot-flux`.

[kluctl/flux-kluctl-controller](https://github.com/kluctl/flux-kluctl-controller)
is a Flux controller for managing [Kluctl](https://kluctl.io) deployments.
Its website explains kluctl as follows

> *Kluctl is the missing glue to put together large Kubernetes
> deployments.*
>
> *It allows you to declare and manage small, large, simple and/or
> complex multi-env and multi-cluster deployments.*
>
> *Kluctl does not have cluster-side dependencies and works out of the
> box.*

[23technologies/gardener-extension-shoot-flux](https://github.com/23technologies/gardener-extension-shoot-flux) is a new integration with Flux. Gardener
implements the automated management and operation of Kubernetes clusters
as a service. With this extension fresh clusters will be reconciled to
the state defined in the Git repository by the Flux controller.

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
May here are a couple of talks we would like to highlight.

Last month was all about KubeCon and there were lots of great sessions
we enjoyed and recommend watching. It might be best if you just head to
our [KubeCon Re-Cap blog post](/blog/2022/05/kubecon-eu-2022-wrap-up/)
and take it from there!

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

📺 [GitOps with Flux on AKS \@AzureKubernetesService (Amsterdam) Meetup - Kingdon Barrett (Weaveworks) & Jonathan Innis (Microsoft)](https://www.youtube.com/watch?v=hoD5-I4DjNY)

📺 [GitOps: Core Concepts & How to Structure Your Repos - Scott Rigby & Priyanka Ravi (Weaveworks)](https://youtu.be/vLNZA_2Na_s)

📺 [DevOpsDays Birmingham AL: GitOps and Flux scaled to 100s of Developers - Bryan Oliver & Kingdon Barrett (Weaveworks)](https://www.youtube.com/watch?v=G8cUcyGD5j4)

📺 [DOK (Data On Kubernetes) \#127: Flux for Helm Users! With Scott Rigby (Weaveworks)](https://youtu.be/xLhBbRkLeAc)

📺 [Community Office Hours: Injecting Secrets from HashiCorp Vault into Flux - Priyanka Ravi (Weaveworks) & Rosemary Wang (Hashicorp)](https://youtu.be/bvs7BkHRpl0)

📺 [Reconcile Terraform Resources the GitOps Way - Priyanka Ravi (Weaveworks)](https://youtu.be/8xhEPPA6XUs)

📺 [GitOps (Flux) Extension for VS Code - Kingdon Barrett (Weaveworks)](https://youtu.be/bY-yFdc73Zc)

### \#flexyourflux

The \#flexyourflux campaign we started for KubeCon is still ongoing.
Until GitOps Days (see below) you can still win a 1h-long 1-on-1 meeting
with Flux Core Maintainer Stefan Prodan.

{{< tweet user=mewzherder id=1526622072960479232 >}}

We will draw the lucky winners live at the [GitOps Days
event](https://www.gitopsdays.com/) (8-9 June).

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
June - tune in to learn more about Flux and GitOps best practices, get
to know the team and join our community.

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2022-06-01 12:00 UTC, 14:00
  CEST](https://www.meetup.com/Weave-User-Group/events/qwbmssydcjbcb/)
- [2022-06-09 17:00 UTC, 1pm
  ET](https://www.meetup.com/Weave-User-Group/events/zzbmssydcjbmb/)
- [2022-06-15 12:00 UTC, 14:00
  CEST](https://www.meetup.com/Weave-User-Group/events/qwbmssydcjbtb/) -
  Host: Sunny
- [2022-06-23 17:00 UTC, 1pm
  ET](https://www.meetup.com/Weave-User-Group/events/zzbmssydcjbfc/)
- [2022-06-29 12:00 UTC, 14:00
  CEST](https://www.meetup.com/Weave-User-Group/events/qwbmssydcjbmc/)

We are flexible with subjects and often go with the interests of the
group or of the presenter. If you want to come and join us in either
capacity, just show up or if you have questions, reach out to Kingdon on
Slack.

We really enjoyed this [demo of the k3d git
server](https://www.youtube.com/watch?v=hNt3v0kk6ec)
recently. It's a local Git server that runs outside of Kubernetes, to
support offline dev in a realistic but also simple way that does not
depend on GitHub or other hosted services.

### GitOps Days 2022

![GitOps Days](gitopsdays-featured.png)

GitOps Days 2022 is a free 2-day online event on June 8-9, 2022 with
Flux center stage!

This is **THE** event for your GitOps journey! Getting started? Taking
GitOps to the next level? We'll cover all of the steps for your success!

The event will run from \~9:00 am PT to \~3:00 pm PT each day as a free
online event.

✨✨ [Register now](https://youtube.com/playlist?list=PL9lTuCFNLaD0NVkR17tno4X6BkxsbZZfr) to
reserve your spot to receive updates to the schedule and speakers. *Join
the conversation!* Chat with the speakers and other attendees! Invite
yourself at [https://slack.weave.works](https://weave-community.slack.com/join/shared_invite/zt-yqwtav03-QPo7W4Qoi1pL6W8UQYk2yQ) and hang out with us at
[\#gitopsdays](https://bit.ly/GitOpsDays_Slack)

- Talks and tutorials on how to get started with Kubernetes and GitOps
- Talks from Flux users about their use cases
- How to do GitOps securely
- Platforms that offer GitOps: Microsoft Arc Kubernetes, AWS Anywhere,
  Weave GitOps, D2iQ Kubernetes Platform, and more! all using Flux!
- Flux in the CNCF and the GitOps Ecosystem
- Flux support and Integrations: Flux + Helm, Terraform, HashiCorp
  Vault, Jenkins, OpenShift, Visual Studio Code, and much much more!
- Technical deep dives with Flux maintainers
- Speakers from Orange, RingCentral, and more just added

## In other news

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[Tietoevry](https://www.tietoevry.com/), [Grafana Labs](https://grafana.com/),
[Aily Labs](https://ailylabs.com/), [SisID](https://sis-id.com/),
[FHE3](https://www.fhe3.com/), [Qualifio](https://qualifio.com),
[Axel Springer SE](https://axelspringer.de),
[Cookpad](https://www.cookpadteam.com/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we
will help to add you. Not only is it great for us to get to know and
welcome you to our community. It also gives the team a big boost in
morale to know where in the world Flux is used everywhere.

If you are like us, you really enjoy hearing adopter use case stories.
At [Gitops Days](https://www.gitopsdays.com/), there will
be loads of those, so join us 8-9 June.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- By updating to the latest hugo and docsy, we were able to drop some
  of our custom code to show e.g. tabs in our documentation.
- We added a gallery shortcode to be able to show a collection of
  pictures nicely.
- New docs for
  - Enable Helm repositories caching
  - Locking down multi-tenant clusters by disabling Kustomize remote
    bases
  - Deploy key rotation
  - How to disable cross namespace references
  - How to bootstrap Flux on GCP GKE with Cloud Source repositories
- New videos added to our [Flux Resources page](/resources/).

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Ihor Sychevskyi, Matt J WIlliams, Paulo Gomes, Alexander Block,
Andreas Loholt, Axel Fontana, Cosmin Banciu, Christian Berendt, Jiri
Tyr, Julien Duchesne, Martin Weber, Max Jonas Werner, Steven Koeberich,
as09.

In particular we would like to thank Ihor Sychevskyi who recently took
on fixing small UI glitches all over the place - especially on mobile
the site should work a lot better now!

### New Project Member: Stacey Potter

{{< imgproc staceypotter Resize 400x >}}
Stacey Potter
{{< /imgproc >}}

We are very happy to announce that [Stacey Potter joined us as a Flux
Project Member](https://github.com/fluxcd/community/issues/210).

Stacey has helped the Flux team out a great deal by organising a lot of
Flux-related events like GitOps Days, Weave Online User Groups, adding
videos to the Flux Resources page and our YouTube playlist, and
coordinating with the team on our Project presence for KubeCon events.
She's such a pleasure to work with and we owe quite a bit of Flux's
success to the stages she created for our speakers.

As a side-note: we updated the [Flux Governance](/governance/) recently to make
it even clearer that we love all kinds of contributions, be they code or
not. We hope that many more of you will follow this path.

{{< tweet user=stacey_potter id=1529450484867731456 >}}

### New Flagger Maintainer: Sanskar Jaiswal

{{< imgproc sanskarjaiswal Resize 400x >}}
Sanskar Jaiswal
{{< /imgproc >}}

Sanskar Jaiswal has been working on Flux and Flagger for quite a while
now. One of his major contributions was to [add Gateway API support to
Flagger](/blog/2022/03/flagger-adds-gateway-api-support/).
We are very pleased to let you know that he [joined the ranks of
Flagger maintainers
now](https://github.com/fluxcd/flagger/pull/1191).

## Flux Project Facts

We are very proud of what we have put together. We want to reiterate
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
1. 🔒 Flux is designed with security in mind: Pull vs. Push,
  least amount of privileges, adherence to Kubernetes security
  policies and tight integration with security tools and
  best-practices. Read more about our security considerations.
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

## Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  2022-06-02 or 2022-06-08.
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
