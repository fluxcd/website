---
title: 'Security: The Value of SBOMs'
url: /blog/2022/02/security-the-value-of-sboms/
author: dholbach
date: 2022-02-07 08:30:00+00:00
description: "The first in our series of blog posts about Flux's security considerations. This time: what a Software Bill of Materials can do to keep you safe."
tags: [security]
resources:
- src: "**.png"
  title: "Image #:counter"
---

## Flux - built with security in mind

You don't get to re-architect a successful project very often, but we
did about two years ago. The Flux project was already off to a great
start and had [many happy adopters](/adopters/#flux-legacy) and many of
its design principles we kept at the forefront of our mind:

- Pull vs Push: if you haven't read this [great blog
  post](https://www.weave.works/blog/why-is-a-pull-vs-a-push-pipeline-important)
  from 2018 about why you want Pull - all it says still holds true.
- Least amount of privileges.
- Reusing best practises, libraries and tools, e.g. client-go and helm
  APIs.
- And more we will explain further down the line.

Why did we re-architect and rewrite Flux? Flux Legacy (v1) had been
started Mid-2016 and while it worked great and still does, it didn't
quite benefit from more recent developments in the Kubernetes space like
[controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
because it pre-dated them significantly.

Also rewriting Flux as a set of very targeted controllers was a unique
opportunity to reduce the scope (and thus attack surface) of these
individual sub-projects and make testing and debugging a lot easier.
Re-usability as well.

All of this said, we believe that a blog series about Flux and its
[security](/flux/security/)
considerations and features is in order and we will kick it off talking
about SBOMs.

### What is a SBOM?

Since Flux release 0.26 we publish a SBOM for each of the individual
controllers. We reported about this in the [accompanying monthly update
blog post](/blog/2022/01/january-update/#-security-enhancements).

So what is a SBOM? It's short for Software Bill of Materials. Wikipedia
defines it as

> A **software bill of materials** (SBOM) is a list of components in a
> piece of software. Software vendors often create products by
> assembling open source and commercial software components. The SBOM
> describes the components in a product. It is analogous to a list of
> ingredients on food packaging: where you might consult a label to
> avoid foods that may cause allergies, SBOMs can help organizations or
> persons avoid consumption of software that could harm them.
>
> The concept of a BOM is well-established in traditional manufacturing
> as part of supply chain management. A manufacturer uses a BOM to track
> the parts it uses to create a product. If defects are later found in a
> specific part, the BOM makes it easy to locate affected products.

For the Flux project we publish a Software Bill of Materials (SBOM) with
each release. The SBOM is generated with
[Syft](https://github.com/anchore/syft) in the
[SPDX](https://spdx.dev/) format.

![SPDX logo](featured-image.png)

The `spdx.json` file is available for download on the GitHub release page
e.g.:

```shell
curl -sL https://github.com/fluxcd/flux2/releases/download/v0.25.3/flux_0.25.3_sbom.spdx.json | jq
```

Inspecting the JSON data, you will see that for each of the files and
libraries required for building and shipping the release you can verify
the license, origin, version and checksum.

What might seem like a lot of overhead and unnecessary bookkeeping,
quickly turns out as useful information because it allows you to

- Verify the origin and integrity of artifacts
- Inspect the dependencies easily for CVEs and known security issues
- Get a holistic view of your complete supply chain, so which other
  dependencies and Open Source projects now become part of your
  stack

Because it is structured data, all of the above can be done in an
automated, programmatic fashion.

Big organizations, corporate or governmental, already keep track of
SBOMs and make decisions based on the information provided there. Some
started requiring SBOMs for software in-use. A good example of this is
the [government of the USA requiring
SBOM](https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/)
from software suppliers.

### Possible use-cases for SBOMs

Here are a couple more concrete examples of what the SBOMs for Flux
allow you to do:

- Security alerts of dependencies will be the most obvious use-case.
  If a CVE is detected, you can inspect your SBOM and see if the
  components you are using are in any way affected.
- It will be easy to identify when a certain component was created and
  how. In addition to that, having the licensing information of all
  the pieces, you better know what you can do with it (redistribute,
  change, etc).
- Automation allows you to send alerts, if a compliance issue is
  detected, e.g. if the licensing of updated/replaced dependencies
  changes.
- Missing components or required build files. Incompatible licenses
  and more.

One example of automating all of this could be to store SBOMs in <https://grafeas.io/>. This way you could search across your Estate for:

- Images that are built from a particular Github commit that is known to have introduced a security problem.
- Find all images that were built by a certain version of a certain builder when that builder is known to have been compromised.
- Find all images in my project that are impacted by `CVE-1234`.

For policy enforcement, [kritis](https://github.com/grafeas/kritis) can be used to leverage the information provided by SBOMs inside Grafeas to enforce policies inside of a cluster, enabling auto-blocking of applications that are vulnerable to a specific CVE for example.

If you have read this far and you are using SBOMs in your organisation,
let us know what you get out of them as well!

### What's more

If you would like to know more about the history of SBOMs and their
development, you might want to read this [excellent article from
ChainGuard](https://blog.chainguard.dev/what-an-sbom-can-do-for-you/)
about the subject.

At the time of writing this, Syft does not yet [classify licenses based
on the file
contents](https://github.com/anchore/syft/issues/656), but
it is being considered.

Here is the table of SBOMs for all the latest Flux controllers and
CLI (as of 2022-02-09).

Project                     | SBOM | Dependencies & Licenses
--------------------------- | ---- | --------
flagger                     | [1.17.0](https://github.com/fluxcd/flagger/releases/download/v1.17.0/flagger_1.17.0_sbom.spdx.json) | [1.17.0](https://deps.dev/go/github.com%2Ffluxcd%2Fflagger/v1.17.0/dependencies)
flux2                       | [0.26.2](https://github.com/fluxcd/flux2/releases/download/v0.26.2/flux_0.26.2_sbom.spdx.json) | [0.26.2](https://deps.dev/go/github.com%2Ffluxcd%2Fflux2/v0.26.2/dependencies)
helm-controller             | [0.16.0](https://github.com/fluxcd/helm-controller/releases/download/v0.16.0/helm-controller_0.16.0_sbom.spdx.json) | [0.16.0](https://deps.dev/go/github.com%2Ffluxcd%2Fhelm-controller/v0.16.0/dependencies)
image-automation-controller | [0.20.0](https://github.com/fluxcd/image-automation-controller/releases/download/v0.20.0/image-automation-controller_0.20.0_sbom.spdx.json) | [0.20.0](https://deps.dev/go/github.com%2Ffluxcd%2Fimage-automation-controller/v0.20.0/dependencies)
image-reflector-controller  | [0.16.0](https://github.com/fluxcd/image-reflector-controller/releases/download/v0.16.0/image-reflector-controller_0.16.0_sbom.spdx.json) | [0.16.0](https://deps.dev/go/github.com%2Ffluxcd%2Fimage-reflector-controller/v0.16.0/dependencies)
kustomize-controller        | [0.20.1](https://github.com/fluxcd/kustomize-controller/releases/download/v0.20.1/kustomize-controller_0.20.1_sbom.spdx.json) | [0.20.1](https://deps.dev/go/github.com%2Ffluxcd%2Fkustomize-controller/v0.20.1/dependencies)
notification-controller     | [0.21.0](https://github.com/fluxcd/notification-controller/releases/download/v0.21.0/notification-controller_0.21.0_sbom.spdx.json) | [0.21.0](https://deps.dev/go/github.com%2Ffluxcd%2Fnotification-controller/v0.21.0/dependencies)
source-controller           | [0.21.2](https://github.com/fluxcd/source-controller/releases/download/v0.21.2/source-controller_0.21.2_sbom.spdx.json) | [0.21.2](https://deps.dev/go/github.com%2Ffluxcd%2Fsource-controller/v0.21.2/dependencies)

This is just one more measure we are taking to keep you more secure.

## Talk to us

We love feedback, questions and ideas, so please let us know how you are
using SBOMs today. Ask us if you have any questions and please

- join our [upcoming dev meetings](/community/#meetings)
- find us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- add yourself [as an adopter](/adopters/) if you haven't already

See you around!
