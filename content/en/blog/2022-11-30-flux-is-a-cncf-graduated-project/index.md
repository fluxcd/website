---
author: dholbach
date: 2022-11-30 9:00:00+00:00
title: Flux is a CNCF Graduated project
description: 'Flux becomes a graduated project within the Cloud Native Computing Foundation. Today is a day to celebrate our hard work as a community!'
url: /blog/2022/11/flux-is-a-cncf-graduated-project/
tags: [announcement]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

![Flux is CNCF Graduated project](flux-graduation-featured.png)

## Flux has graduated

Today is a very exciting day for the Flux community! Flux is now a
[graduated project](https://www.cncf.io/announcements/2022/11/30/flux-graduates-from-cncf-incubator/)
in the Cloud Native Computing Foundation and joining the ranks of
Kubernetes, Helm, Prometheus and others in this category.

## Flux History

We all worked very hard to make this happen - it is another important
milestone in the Flux success story. Started in July 2016, engineers at
Weaveworks built the first version of Flux to guarantee predictable
deployments internally. This was way before Kubernetes had won the Cloud
Native market.

In the coming years at Weaveworks, the learnings with Flux helped to
establish and refine the principles of GitOps. Flux was integrated ever
more closely with Kubernetes, and later on Helm and Kustomize. It also
grew a community and an ecosystem. In 2018, Flagger was born, a Flux
companion that made progressive delivery a natural extension of GitOps.

When Weaveworks donated Flux and Flagger to the CNCF, we already saw
large-scale adoption growing and cloud vendors making the Flux suite
core of their offerings to provide GitOps functionality.

This was also the point where we decided to rewrite Flux from scratch,
using modern tooling such as controller-runtime and as a set of targeted
controllers, which made Flux development a lot more straight-forward. In
the past weeks we archived Legacy Flux and are very close to making Flux
v2 GA. Watch this space for the announcement!

> "We created Flux as open source from the beginning, in order to work
> out in the open. It was very gratifying therefore, and far from
> inevitable, that a loyal and mutually supportive community grew around
> it. Making that happen takes a lot of empathy and patience from all
> involved -- so, thank you everyone, for carrying Flux ever further."
>
> -- Michael Bridgen, co-creator of Flux

## Flux's home: the CNCF

Today is a great time to look back at our time in the CNCF. We wouldn't
be where we are today without the services and help of people at the
CNCF. It wasn't just the great benefits and infrastructure we enjoy as a
project, but also the careful guidance and collaboration of CNCF groups
such as the TOC, TAG Security / TAG Contributor Experience and all the
adjacent project communities which also live at the CNCF. We also would
like to thank our TOC sponsor, Matt Farina, who helped us navigate this
process and encouraged us to take Flux even further!

> "I feel humbled and honored to be part of the Flux & Flagger team for
> the past five years. With the help of our community, we have come a
> long way since Flux inception and the start of the GitOps movement.
> Today, Flux is an established continuous delivery solution for
> Kubernetes, trusted by organisations around the world and backed by
> vendors like Amazon AWS, D2iQ, Microsoft Azure, VMware, Weaveworks and
> others that offer Flux to their users. The Flux team is very grateful
> to the cloud-native community and CNCF who supported us over the years
> and made Flux what it is today"
>
> -- Stefan Prodan, Flux maintainer and creator of Flagger

During the Graduation process, we particularly reflected on security and
governance. We threat-modelled the Flux components, which resulted in
documented security best practice. We will continue to educate our user
community on how to use Flux securely. Today both Flux and Flagger are
100% compliant with the CLO monitor, which is the [highest score
amongst graduated CNCF
projects](https://clomonitor.io/search?maturity=graduated&foundation=cncf&page=1).
We streamlined our security processes, and have regular conversations
with security professionals from CNCF tag-security. Soon we are going to
undergo a second security audit for an external validation of all the
great work we have done over the last few years.

We are incredibly proud of what we have achieved and what we have given
to the wider ecosystem. GitOps is close to becoming the de-facto
standard. Cloud vendors offer GitOps capabilities to their customers
these days, a lot of this is based on Flux as a technology and the
learnings we made until today. We are extremely pleased to have this
[huge ecosystem](/ecosystem/) built on
top of and around Flux, including recent [Flux
UIs](/ecosystem/#flux-uis--guis)!

## Next up: Flux going GA

The 2.0.0 release of Flux is drawing near as well!

While Flux has been production ready for quite some time, we have an
extremely strict backwards compatibility policy and take major versions
very seriously.

The Flux community was working on a number of concurrent projects at the
same time: qualifying for Graduation, refactoring the controllers to
standardise the internal APIs, stabilizing the use of APIs of e.g. Helm
and Git, integrating OCI artifacts and Cosign verification fully into
Flux, and more. All of these workstreams were happening at the same
time. To make it clear to everyone what a GA release for Flux would look
like, we've updated [our GA
roadmap](/roadmap/). There are many
important details here for those following the 2.0.0 release, but one
thing that is very important to us is further stabilizing Flux and its
APIs so it will be even easier for new community members to contribute
and build on top of Flux!

## 💖 Huge thank-you

You are all rock stars! 🤩 Continued thanks to everyone of our Flux
community members who have, in ways small and large, contributed to the
success of Flux!

If you want to celebrate with us or are now more curious about Flux, please join us at our Flux Graduation Ask-Us-Anything sessions:

- [December 7, 12:00 UTC](https://zoom.us/j/4381188348) with Flux maintainers: Daniel, Max, Philip, Sanskar, Stefan, Somtochi
- [December 8, 18:00 UTC](https://weaveworks.zoom.us/j/85821738864?pwd=cjk4QjRabEpUVlRlcFBqMm9UZ2xNZz09) with Flux maintainers: Kingdon, Paulo, Somtochi, Soulé

We are looking forward to seeing you and getting to know you there!
