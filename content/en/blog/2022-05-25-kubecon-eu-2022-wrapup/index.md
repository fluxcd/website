---
author: dholbach
date: 2022-05-25 10:00:00+00:00
title: 'KubeCon EU 2022 Wrap-Up'
description: "KubeCon EU 2022 is over and we lots of fun being there and meeting you! If you couldn't make it, read the blog post and catch up with everything that happened. We have links to all the currently available talks and lots of pics from the event!"
url: /blog/2022/05/kubecon-eu-2022-wrap-up/
tags: [event]
resources:
- src: "**.{jpg,png}"
  title: "Image #:counter"
---

It was KubeCon + CloudNativeCon EU 2022 last week and if you weren't
able to attend, this post provides you with everything you need to know
about Flux and GitOps that happened there. The schedule was packed with
case studies, development updates and many new friendships formed at our
booths and in the hallway track.

{{< imgproc kubecon-welcome Resize 600x >}}
{{< /imgproc >}}

{{< tweet user=stefanprodan id=1526120707993878531 >}}

## Monday

On Monday we kicked off the day for Flux with a Project Meeting. We are
grateful we had this opportunity through the CNCF to offer a 4 hour
event available to any interested community members. Stefan Prodan,
Leigh Capili and Priyanka Ravi led various talks and provided a great
and very diverse overview of what's happening in Flux and adjacent
tooling these days and how to best take advantage of it.

{{< imgproc project-meeting Resize x600 >}}
{{< /imgproc >}}

{{< tweet user=fluxcd id=1526216149821800448 >}}

Thanks as well Vanessa Abankwah for pulling all the strings in the
background!

The Cloud Native Telco Day was happening as well on Monday and
[Philippe Ensarguet](https://twitter.com/P_Ensarguet), CTO
at Orange Business, live-tweeted some of the learnings there. We are
very pleased to know that [the GitOps setup of Swisscom is based on
Flux](https://twitter.com/P_Ensarguet/status/1526106080375349248).
[Deutsche Telekom is continuing their voyage on Das Schiff together
with
Flux](https://twitter.com/P_Ensarguet/status/1526117412629790721)
as well.

## Tuesday - GitOpsCon

Who would have thought a couple of years ago that one day we would have
an entire conference day just about GitOps - this year it was two
simultaneous tracks no less. We want to thank the [Open
GitOps](https://opengitops.dev/) group for organising this
and inviting great speakers from across all of the GitOps space!

{{< imgproc gitopscon Resize 600x >}}
Taken from the <a href="https://www.flickr.com/photos/143247548@N03/52080186019">CNCF flickr account</a>.
{{< /imgproc >}}

{{< tweet user=P_Ensarguet id=1526460515823779843 >}}

Here is our own small selection of favourites. If you want to see all
the talks from GitOpsCon, take a look at the [YouTube channel of the
Cloud Native Computing
Foundation](https://www.youtube.com/c/cloudnativefdn) -
there are loads more.

- [Crossing the Divide: How GitOps Brought AppDev & Platform Teams
  Together!](https://www.youtube.com/watch?v=0jNtDnWT3yo) -
  Priyanka \"Pinky\" Ravi, Weaveworks
- [Michael Irwin](https://twitter.com/mikesir87) on
  using Flux for multi-tenancy: [Creating A Landlord for
  Multi-tenant K8s Using Flux, Gatekeeper, Helm, and Friends -
  Michael Irwin](https://youtu.be/agsnktpIxzU)
- AppsFlyer talks about Flux at the core of their huge infra:
  - [GitOps Everything!? We Sure Can!, Ayelet de-Roos,
    AppsFlyer](https://youtu.be/qGQyGuoS5Ds)
  - [We Have Always Done It This Way! Now Let's Try Something
    Completely Different - Eliran
    Bivas](https://youtu.be/es5ngkzJDEc)
- Max' talk about Flux for multi-cluster envs: [Managing Thousands of
  Clusters and Their Workloads with Flux - Max Jonas Werner,
  D2iQ](https://youtu.be/Xei2ZcEg5B0)
- Environment promotion (Form3): [Solving Environment Promotion with
  Flux - Sam Tavakoli & Adelina Simion,
  Form3](https://youtu.be/gqs4mVppn1Q)
- Lightning Talks:
  - Secret decryption: [Lightning Talk: Hiding in Plain Sight - How
    Flux Decrypts Secrets - Somtochi Onyekwere,
    Weaveworks](https://youtu.be/2rJur5VE6yA)
  - Progressive delivery: [Lightning Talk: GitOps and Progressive
    Delivery with Flagger, Istio and Flux - Marco Amador,
    Anova](https://youtu.be/AKVfqn85ZJ4)
  - [GitOps, A Slightly Realistic Situation on Kubernetes with
    Flux](https://www.youtube.com/watch?v=uU-zbTgbHPI) -
    Laurent Grangeau, Google & Ludovic Piot, theGarageBandOfIT

## Wednesday - Friday - KubeCon

Wednesday through Friday was the main event, with the big keynotes,
talks on many different tracks and a big booth space. We are happy we
had such a great team at the Flux booth because ours was massively
frequented and our team gave a huge amount of demos, answered questions
and were there to hang out with.

In addition to the physical booth in Valencia, we had a virtual booth as
well, where Kingdon Barrett held our weekly Bug Scrub event and we gave
a number of lightning talks as well.

### Lightning talks at the virtual booth

First up was Sanskar Jaiswal, Software Engineer at Weaveworks, who
recently became Flagger maintainer and contributed Gateway API support.
Watch the demo here:

{{% youtube pN41tIKn3eE %}}

We were happy to have Rosemary Wang, Developer Advocate at HashiCorp,
there who walked us through securing secrets in Flux by using Vault:

{{% youtube 6gwgG6yhN04 %}}

## \#flexyourflux

Another contributing factor to the amount of people coming to our booth
was the \#flexyourflux campaign, where you could

1. Get a nice "flex your flux" t-shirt for answering a couple of
   questions about Flux
1. Win an opportunity to have a 1-on-1 1h long meeting with Stefan
   Prodan, Flux core maintainer

{{< imgproc flexyourflux Resize 512x >}}
{{< /imgproc >}}

{{% tweet user=mewzherder id=1526622072960479232 %}}

The t-shirts were only available in person, but the meeting with Stefan
you can still win, simply enter by filling out
[https://bit.ly/flexyourflux](https://bit.ly/flexyourflux).
We will draw the winners live at GitOps Days (see below). Good luck to
all participants!

## Talks you might have missed

### Getting Started with Flux and GitOps

Tiffany Wang from Weaveworks and Joaquin Rodriguez led through a 1.5h
hands-on tutorial called "[Intro to Kubernetes, GitOps and
Observability](https://kccnceu2022.sched.com/event/ytkj)".
The idea was to offer newcomers a quick way to experience Kubernetes and
its natural evolutionary developments: GitOps and Observability.
Attendees were able to use and experience the benefits of Kubernetes
that impact reliability, velocity, security, and more. The session
covered key concepts and practices, as well as offer attendees a way to
experience the commands in real-time. The tutorial covers: kubectl, K9s,
Metrics (Prometheus), Dashboards (Grafana), Logging (Fluent Bit),
GitOps (Flux).

The feedback we heard from people on the ground was that they had a
blast. If you missed it: good news - it'll be happening at [GitOps
Days](https://www.gitopsdays.com/) as well!

### The Flux Deep Dive

Stefan Prodan delivered the Flux Deep Dive session - this time focused
on security aspects.

{{< imgproc deep-dive1 Resize 700x >}}
{{< /imgproc >}}
{{< imgproc deep-dive2 Resize 700x >}}
{{< /imgproc >}}

{{% tweet user=nmeisenzahl id=1526875153090715650 %}}

There was a lot to be learnt and since security has been such a big
focus for the entire team since the rewrite of Flux, also a lot to catch
up on.

Stefan will give his talk at GitOps Days too (see below).

### Flux Virtual Office Hours

Flux Maintainers Paulo Gomes & Kingdon Barrett hosted the Flux Virtual
Office Hours where they covered the latest Flux features, what’s coming
soon, and an intro to debugging the controllers for new contributors.
Check out the replay here:

{{% youtube BrYgx4cB7p4 %}}

### What's more

Obviously the hallway track is one of the key events at KubeCon. It's
where you find new friends, learn and make new plans with other
community members. There was a lot of this at the booth, at lunch and at
the evening events.

In addition to that, many new users and community members find their way
to Slack, our Twitter and LinkedIn group. We are also especially pleased
that some new adopters [added themselves to our website](/adopters/) -
remember that's one of the safest ways to make Flux maintainers happy. 🥰

We expect that more talk videos are going to get to us in the next days
and we will make sure to mention them all on [our resources
page](/resources/) and in [our monthly updates](/tags/monthly-update/).

## Outlook: GitOps Days

If you had a FOMO experience over the last week, we are happy to let you
know that GitOps Days are coming up! A free, two days event with lots of
great talks, a lot of fun and lots to catch up with in case you missed
seeing talks at KubeCon.

{{< imgproc GitOps-Days-2022-Logo-1 Resize 500x >}}
{{< /imgproc >}}

> [**GitOps Days!**\
> **June 8-9, 2022**](https://www.gitopsdays.com)

This is THE event for your GitOps Journey! Getting started? Taking
GitOps to the next level? We'll cover all of the steps for your success!

Come hear from speakers like Taylor Dolezal (CNCF), Anaïs Urlichs (Aqua
Security, CNCF Ambassador), Viktor Farcic (Upbound/Crossplane), Mae
Large (VMware), Rosemary Wang (HashiCorp), Jason Morgan
(Buoyant/Linkerd), and so many more!

## Big Thank You

This wouldn't have been possible without the support of many many
people.

People speaking: Stefan Prodan, Somtochi Onyekwere, Max Jonas Werner,
Priyanka Ravi, Tiffany Wang, Paulo Gomes, Scott Rigby, Kingdon Barrett,
Sanskar Jaiswal and others.

Folks organising, writing, fact-checking and supporting the booth:
Vanessa Abankwah, Stacey Potter, Tamao Nakahara, Juozas Gaigalas and
others.

And of course many people from adjacent communities, adopter companies
and of course the CNCF.

Sorry if we missed to mention anyone.

And in closing out, here is a short selection of [official KubeCon
photos](https://www.flickr.com/photos/143247548@N03/), all around Flux and GitOps:

{{< gallery match="flickr/*" sortOrder="desc" rowHeight="150" margins="5"
            previewType="blur" embedPreview=true >}}
