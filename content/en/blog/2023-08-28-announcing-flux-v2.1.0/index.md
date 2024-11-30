---
author: somtochiama
date: 2023-09-04 00:00:00+00:00
title: Announcing Flux 2.1 GA
description: "Flux v2.1.0: New monitoring setup with support for custom metrics, performance improvements and much more!"
url: /blog/2023/08/flux-v2.1.0/
tags: [announcement]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

## New releases

We are happy to announce the latest GA releases for Flux and Flagger.

### Flux v2.1.0

This new release comes with lots of new features,
fixes, restructured documentation and performance improvements.
Everyone is encouraged to upgrade for the best experience.

The [Flux APIs](https://github.com/fluxcd/flux2/releases/tag/v2.1.0#api-changes)
were extended with new opt-in features in a backwards-compatible manner.

The Flux Git capabilities have been improved with support for
Git push options, Git refspec, Gerrit, HTTP/S and SOCKS5 proxies.

In case you missed it, Flux reached General Availability in June.
You can read the announcement
[here](https://fluxcd.io/blog/2023/07/flux-ga/).

You can now check the end-of-life(EOL) dates and support information for
different Flux versions at https://endoflife.date/flux.

#### Features

- The [GitRepository API](https://fluxcd.io/flux/components/source/gitrepositories/#proxy-secret-reference)
  has a new field `.spec.proxySecretRef` that is used for specifying proxy configuration to use
  for all remote Git operations related to the particular object.
- The`.spec.verify.mode` field of the [GitRepository API](https://fluxcd.io/flux/components/source/gitrepositories/#verification)
  now accepts one of the following values `HEAD`, `Tag`, `TagAndHEAD`. These values are used to specify
  how the Git tags and commits are verified.
- The [server-side apply behaviour](https://fluxcd.io/flux/components/kustomize/kustomizations/#controlling-the-apply-behavior-of-resources)
  in the kustomize-controller has been extended with two extra policies:
  `IfNotPresent` and `Ignore`. These policies are specified with the `kustomize.toolkit.fluxcd.io/ssa`
  annotation on the resource manifest. The `IfNotPresent` policy is useful to have Flux create an object
  that will later be managed by another controller.
- Support for sending notifications to [DataDog](https://fluxcd.io/flux/components/notification/providers/#datadog).
- The [ImageUpdateAutomation API](https://fluxcd.io/flux/components/image/imageupdateautomations/#push) has two
  new optional fields - `.spec.git.push.refspec` and `.spec.git.push.options` for to specify a refspec and push
  options that will be used when pushing commits upstream.

#### Fixes and improvements

Here is a short list of features and improvements in this release:

- A new flag `--concurrent-ssa` has been introduced in the kustomize-controller to set the number of concurrent
 server-side operations that will be performed by the controller per object. This increases speed when
 reconciling Kustomization with a considerable amount of objects.
- Performance improvement when loading helm repositories with large indexes (up to 80% memory reduction).
- The load distribution has been improved when reconciling Flux objects in parallel to reduce CPU and memory spikes.
- The Installation and Monitoring sections of the Flux documentation have been restructured to make navigation
  and locating guides easier. We are always open to receiving feedback on how we can improve the documentation.

#### Deprecation

- All APIs that accept TLS data have been modified to support Kubernetes TLS style secrets.
  The keys `caFile`, `certFile` and `keyFile`  have been deprecated. For more details about the TLS changes 
  please see the [Kubernetes TLS Secrets section](https://github.com/fluxcd/flux2/releases/tag/v2.1.0#kubernetes-tls-secrets).
- ⚠️ Breaking changes: This release comes with breaking changes to the Flux monitoring stack (Prom+Grafana).
  The stack now leverages the
  [kube-state-metrics Custom Resource State metrics](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/customresourcestate-metrics.md)
  to report some Flux resource metrics. This will allow users to extend the Flux metrics with custom metadata. The
  [monitoring configuration in the fluxcd/flux2 repository](https://github.com/fluxcd/flux2/tree/v2.1.0/manifests/monitoring#warning-deprecation-notice)
  is now deprecated and will be removed in a future release. The new monitoring configuration is located at
  [fluxcd/flux2-monitoring-example](https://github.com/fluxcd/flux2-monitoring-example/).
  Please see the new monitoring guide https://fluxcd.io/flux/monitoring for more information.

#### Upgrade

To upgrade Flux from v0.x to v2.1.0 please follow the
[Flux GA upgrade procedure](https://github.com/fluxcd/flux2/releases/tag/v2.0.0#upgrade).

To Upgrade Flux from v2.0.x to v2.1.0 either by [rerunning bootstrap](https://fluxcd.io/flux/installation/#bootstrap-upgrade)
or by using the [Flux GitHub Action](https://github.com/fluxcd/flux2/tree/main/action).

You can take a look at the [changelog](https://github.com/fluxcd/flux2/releases/tag/v2.1.0) for the full list of changes.

❣️Big thanks to all the Flux contributors who helped us with this release!

#### Flux Grafana Dashboards

The Flux monitoring stack comes with two dashboards
for easy visualization of Flux controllers and resource metrics. 
You can follow this [link](https://github.com/fluxcd/flux2-monitoring-example)
to learn how to set it up.

{{< gallery match="images/*" sortOrder="desc" rowHeight="150" margins="5"
      thumbnailResizeOptions="900x900 q90 Lanczos"
      previewType="blur" embedPreview=true lastRow="nojustify" >}}


### Flagger v1.33.0

This release fixes bugs related to the Canary lifecycle. The `confirm-traffic-increase` webhook
is no longer called if the Canary is in the `WaitingPromotion` phase. Furthermore, a bug which
caused downtime when initializing the Canary deployment has been fixed. Also, a bug in the
`request-duration` metric for Traefik which assumed the result to be in milliseconds
instead of seconds has been addressed.

The loadtester now also supports running `kubectl` commands.

Please see the [changelog](https://github.com/fluxcd/flagger/blob/main/CHANGELOG.md#1310) for the full changes.

## Community News

This section highlights additions to our community -
new contributors, project members, maintainers or adopters.

### New adopters

{{< gallery match="logos/*" sortOrder="desc" rowHeight="20" margins="20"
    thumbnailResizeOptions="300x300 q90 Lanczos"
    previewType="blur" embedPreview=true lastRow="nojustify" >}}

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:

- [Zeit Online](https://www.zeit.de): a  German-language platform for demanding online journalism
  and reader discussions with level.
- [Sonatype](https://sonatype.com): a developer-friendly full-spectrum software supply chain management
  platform helps organizations and software developers.
- [Prophesee](https://www.prophesee.ai): a company using sensor design and AI algorithms
  to develop computer vision systems.
- [Infolegale](https://www.infolegale.fr): a legal information platform to monitor company solvency.
- [Eco Vadis](https://ecovadis.com/): a collaborative platform that allows companies to assess the environmental
  and social performance of their suppliers.

_If you have not already done so, [use the instructions here](/adopters/)
or give us a ping and we will help to add you. Not only
is it great for us to get to know and welcome you to our community. It
also gives the team a big boost in morale to know where in the world
Flux is used everywhere._

### New Contributors

Shoutout to all our new contributors:

- [Arukiidou](https://github.com/arukiidou)
- [Brian Dols](https://github.com/bdols)
- [Chip Zoller](https://github.com/chipxoller)
- [Frank J Kelly](https://github.com/kellyfj)
- [Gerard Krupa](https://github.com/GJKrupa)
- [Marcus Weiner](https://github.com/mraerino)
- [Mihai Ratoiu](https://github.com/mihaiandreiratoiu)
- [Stéphane Este-Gracias](https://github.com/sestegra)
- [Stephan Scheying](https://github.com/scheying)

Thanks to all of our old and new contributors, and reach out if you'd like to become one as well.

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section!

#### [How to Build a Self-Service Platform on Upbound: Day 1](https://blog.upbound.io/upbound-day-1)

Our friends at Upbound wrote a great blog post on how you can use the power of Flux and Crossplane to
drive control plane interactions and configure your control plane for GitOps Flows.

#### [Canary deployment with Flagger and Istio on Devtron](https://www.cncf.io/blog/2023/08/23/canary-deployment-with-flagger-and-istio-on-devtron/)

Rupin Solanki describes how to leverage Flagger and Istio, to automate the canary release process, ensure seamless
traffic shifting and real-time application health monitoring.

## Events

It's important to keep you up to date with events
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events

In August here are a couple of talks we would like to highlight.

#### Cloud Native Islamabad - Harnessing the Power of GitOps with Flux

Flux maintainer, Stefan Prodan spoke at Cloud Native Islamabad on Harnessing the Power of GitOps with Flux.
It is packed with a informed introduction to the concept of GitOps and a demo of Flux and the Weave GitOps UI!
Click on the video below to watch it.

{{< youtube id=tkC6qrIzA_s >}}

### Upcoming Events

We are happy to announce that we have a number of events coming up.
Tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

#### Share your story at GitOpsCon EU(virtual) this year! 📆

If you wish to speak at GitOpsCon EU, reach out to us to collaborate on proposals
on a range of topics related to Kubernetes. We are happy to provide our writing
expertise to your proposal and to collaborate on ideas. The
[CFP](https://events.linuxfoundation.org/gitopscon-europe/program/cfp/) deadline is October 4,
so kindly contact tamao@weave.works ASAP if you’re interested.
The conference will take place virtually on the 5th - 6th of December.

#### CNCF On-Demand Webinar

Flux Maintainer, Kingdon B will be giving a talk titled 
`How to start building a self-service infrastructure platform on Kubernetes` on the 14th of September.
It’s going to be packed with knowledge on how to use Backstage and GitOps.
Register [here](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-how-to-start-building-a-self-service-infrastructure-platform-on-kubernetes/).

### Project meetings and Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one of
the best ways to get involved in Flux. They are a friendly and welcoming way
to learn more about contributing and how Flux is organised as a project.

- 2023-09-05 22:00 UTC, 00:00 CEST [The Flux Bug Scrub (AEST)](/#calendar)
- 2023-09-06 12:00 UTC, 14:00 CEST [The Flux Bug Scrub](/#calendar)
- 2023-09-07 15:00 UTC, 17:00 CEST [CNCF Flux Project Meeting (late)](/#calendar)
- 2023-09-13 12:00 UTC, 14:00 CEST [CNCF Flux Project Meeting (early)](/#calendar)
- 2023-09-14 17:00 UTC, 19:00 CEST [The Flux Bug Scrub](/#calendar)
- 2023-09-19 22:00 UTC, 00:00 CEST [The Flux Bug Scrub (AEST)](/#calendar)

*We are flexible with subjects and often go with the interests of the
group or of the presenter. If you want to come and join us in either
capacity, just show up or if you have questions, reach out to Kingdon B on
Slack.*

## Flux Ecosystem

### Terraform-controller

The ecosystem is buzzing with news about the licensing changes to Hashicorp’s open-source projects
including Terraform. Weaveworks has released a
[statement](https://web.archive.org/web/20230925073503/https://www.weave.works/blog/statement-for-terraform-hashicorp-license-changes)
on this and the impact on the tf-controller.

### VS Code GitOps Extension

Significant performance upgrades and code refactoring has been introduced with VS Code GitOps Tools
extension version 0.25.0. Previously cluster metadata was loaded using `kubectl get` commands.
Now, a new javascript client is also used which permits faster loading and real-time watching of cluster resources.
`kubectl proxy` is executed in the background for the new client. Rendering of resource treeviews has been reworked
to minimise data reloading, to maintain collapsible state and to allow visualising resource errors grouped
by namespaces. Timeout settings were added and bad cluster connections should no longer slow down Clusters treeview rendering.

UI refinements and bug fixes for the new client are ongoing. The most up-to-date UI features can be previewed by
selecting “Install Pre-Release Version” in the VS Code Extension Browser.

## Flux Fun Fact!

Did you know …
🔒 Flux is designed with security in mind: Pull vs. Push,
least amount of privileges, adherence to Kubernetes security
policies and tight integration with security tools and
best-practices. Read more about our security considerations.

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

