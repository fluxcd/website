---
author: dholbach
date: 2022-10-26 13:20:00+00:00
title: "CNCF Talk: Increased security and scalability with OCI"
description: "Watch Flux Core Maintainer Max Jonas Werner's talk about OCI support in Flux. Intro to GitOps, Flux and OCI and a great demo of what's all possible."
url: /blog/2022/10/cncf-talk-flux-oci/
tags: [event, oci]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

Integrating OCI into Flux was one of the most-requested features of all
times. We listened to your feedback and in the past couple of releases,
OCI was integrated more deeply into Flux. Here is a brief summary of
what landed when:

- v0.31 (Jun 2022): Support for Helm repositories of type OCI
- v0.32 (Aug 2022): Kubernetes manifests, Kustomize overlays and
  Terraform code as OCI artifacts
- v0.33 (Aug 2022): More configurability of OCI settings
- v0.34 (Sep 2022): More flexibility when interacting with OCI
  artifacts/repositories
- v0.35 (Sep 2022): verify OCI artifacts signed by cosign
- v0.36 (Oct 2022): verify OCI helm charts signed by cosign plus lots
  of new tooling to interact with OCI using the Flux CLI

To bring you up to speed with what's possible, Max Jonas Werner, Flux
Core Maintainer and Senior Software Engineer at Weaveworks, gave a talk
in the CNCF Online Programme series to give some background and do a
practical demo.

First off, Max explained the core GitOps concepts and gave an overview
of the architecture of Flux. In the next step, he dived into how Docker
and others created the Open Containers Initiative (OCI) which is a part
of the Linux Foundation.

One of the key points Max is making is that we went through a
transformation from Docker containers to generic application and
configuration containers. More and more OCI is becoming an application
delivery format.

OCI registries (which implement the distribution spec) are a commodity
in the cloud space. This means that it's very easy to get enhanced
scalability this way, because pulling an OCI image is much less
resource-intensive compared to a full or shallow Git clone.
Additionally, high available registries are available everywhere.

It also provides many ways to secure your infrastructure. [Flux
leverages Kubernetes workload identity and
IAM](/flux/components/source/helmrepositories/#provider)
when pulling OCI artifacts from managed registries. So no more key
management, no more SSH keys to generate, no more proprietary API usage
for token generation. You use the same mechanism that is used for
pulling container images. You might also want to check out this post
about [verifying authenticity of artifacts with
cosign](/blog/2022/10/prove-the-authenticity-of-oci-artifacts/).

Max spends more than half of his presentation time for the demo, so you
get a good idea of how to use these new features and integrate them into
your setup.

Check out the video here:

{{< youtube l5pVzP6wsP0 >}}

Thanks a lot Max for taking the time to walk us through this!

Start your journey and start [using Flux's OCI
features](/flux/cheatsheets/oci-artifacts/) today.
