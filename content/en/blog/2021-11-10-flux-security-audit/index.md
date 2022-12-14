---
author: dholbach
date: 2021-11-10 12:30:00+00:00
title: Flux Security Audit has concluded
description: Flux just went through a CNCF-funded Security Audit. Here we publicly release and discuss the report. We also disclose our first CVE, which was fixed in Flux v0.18.0 - please upgrade as soon as you can!
url: /blog/2021/11/flux-security-audit
aliases: [/blog/2021-11-10-flux-security-audit/]
tags: [security, announcement]
resources:
- src: "**.png"
  title: "Image #:counter"
---

As Flux is an Incubation project within the [Cloud Native Computing
Foundation](https://www.cncf.io/), we were graciously
granted a sponsored audit. The primary aim was to assess Flux's
fundamental security posture and to identify next steps in its security
story. The audit was commissioned by the CNCF, and facilitated by
[OSTIF](https://ostif.org/) (the Open Source Technology
Improvement Fund). [ADA Logics](https://adalogics.com/)
was quickly brought into the picture, and spent a month on the audit.

The Flux maintainers and community are very grateful for the work put
into this by everyone and the opportunity to grow and improve as a
project.

![ADA Logics, CNCF, OSTIF](featured-image.png)

## Our first CVE in Flux

Let's start with what will likely interest you as a Flux user. The
engagement uncovered a privilege escalation vulnerability in Flux that
could enable users to gain cluster admin privileges. The issue has been
fixed and is assigned CVE 2021-41254, and the full disclosure advisory
is available at the following link:

CVE-2021-41254: [Privilege escalation to cluster admin on multi-tenant
Flux](https://github.com/fluxcd/kustomize-controller/security/advisories/GHSA-35rf-v2jv-gfg7).

Description:

Users that can create Kubernetes Secrets, Service Accounts and Flux
`Kustomization` objects, could execute commands inside the
`kustomize-controller` container by embedding a shell script in a
Kubernetes Secret. This can be used to run `kubectl` commands under the
Service Account of `kustomize-controller`, thus allowing an authenticated
Kubernetes user to gain cluster admin privileges.

Impact:

Multi-tenant environments where non-admin users have permissions to
create Flux `Kustomization` objects are affected by this issue.

Fix:

This vulnerability was fixed in `kustomize-controller` v0.15.0 (included
in Flux v0.18.0) released on 2021-10-08. Starting with v0.15, the
`kustomize-controller` no longer executes shell commands on the container
OS and the `kubectl` binary has been removed from the container image.

## Audit report with full details

We are thankful for the great attention to detail by the team at ADA
Logics. The whole report can be found [here](/FluxFinalReport-v1.1.pdf).
To benefit from the analysis in all its detail, we created a [project
board](https://github.com/orgs/fluxcd/projects/5) in
GitHub. If you take a look at it closely, you will see that we have
fixed some of the most immediate issues already.

Broadly speaking, the issues fall into three categories:

1. Enabling Fuzzing for the Flux project
1. Documentation issues
1. Concrete issues discovered in the Flux code

### Flux coming to OSS-Fuzz

The team at ADA Logics didn't stop at reviewing Flux code. We were
pleasantly surprised to receive actual PRs by the team, who set down and
helped us integrate with the OSS-Fuzz project. Some of this work still
needs to be integrated into all of the Flux controllers, but we are very
pleased that a start has been made! OSS-Fuzz is a service for running
fuzzers continuously on important open source projects, and the goal is
to use sophisticated dynamic analysis to uncover security and
reliability issues. There are already numerous other CNCF projects
integrated, e.g. Kubernetes, Envoy and Fluent-bit, and we're excited to
be a part of that.

### Our documentation from an outside perspective

One very important piece of feedback was that our documentation is
mostly geared towards end users, who need very concrete advice on how to
integrate Flux into their setups. We provide lots of examples, which are
helpful if you want Flux to behave the right way. What is missing to
date is an architectural overview and documentation which focuses on the
security-related aspects of Flux.

### What transpired during the code review

The team at ADA Logics found 22 individual issues, some of which were
results from the fuzzers. 1 high severity (that's the above mentioned
CVE), 3 medium severity, 13 low severity and 5 informational.

We appreciate the attention to detail by the team at ADA Logics. The
issues range from dependency upgrades to oversights in the code (files
which aren't closed during an operation, unhandled errors) to misleading
documentation.

Issue | Severity
----- | --------
1:  [Arbitrary command execution via command injection in the kustomize controller by way of secrets](https://github.com/fluxcd/kustomize-controller/security/advisories/GHSA-35rf-v2jv-gfg7) | High
2:  [Nil-dereference in image-automation controller](https://github.com/fluxcd/image-automation-controller/issues/246) | Low
3:  [Credentials exposed in environment variables and command line arguments](https://github.com/fluxcd/flux2/issues/2011) | Medium
4:  [Use of deprecated library](https://github.com/fluxcd/flux2/issues/1658) | Low
5:  [Invalid and missing testing documentation](https://github.com/fluxcd/community/issues/133) | Informational
6:  [Bug fixes do not always include regression tests](https://github.com/fluxcd/.github/issues/8) | Informational
7:  [Deprecated SHA-1 is used for checksums](https://github.com/fluxcd/source-controller/issues/467) | Low
8:  [Missing checksum verification](https://github.com/fluxcd/source-controller/issues/468) | Medium
9:  [Inconsistent and missing logging](https://github.com/fluxcd/pkg/issues/172) | Low
10: [Reading large files can crash flux with an out-of-memory bug](https://github.com/fluxcd/source-controller/issues/470) | Low
11: [Files are opened but never closed](https://github.com/fluxcd/source-controller/issues/471) | Low
12: [Unhandled error](https://github.com/fluxcd/image-automation-controller/issues/242) | Low
13: [Slice bounds out of range](https://github.com/fluxcd/image-automation-controller/issues/243) | Low
14: [Possible nil-deref in image-automation controller](https://github.com/fluxcd/image-automation-controller/issues/246) | Low
15: [Inconsistent code-styles and potential nil-dereferences](https://github.com/fluxcd/pkg/issues/173) | Informational
16: [Missing return statement after error](https://github.com/fluxcd/image-automation-controller/issues/244) | Low
17: [File extension comparisons are case sensitive](https://github.com/fluxcd/kustomize-controller/issues/476) | Low
18: [Some dependencies are outdated](https://github.com/fluxcd/source-controller/issues/472) | Informational
19: [Lack of container security options in deployed pods](https://github.com/fluxcd/flux2/issues/2014) | Low
20: [Unhandled errors from deferred file close operations](https://github.com/fluxcd/pkg/issues/174) | Low
21: [x509 certificates are not used for Webex](https://github.com/fluxcd/notification-controller/issues/278) | Medium
22: [Unnecessary conditions in the code](https://github.com/fluxcd/image-automation-controller/issues/245) | Informational

At the time of writing, 43% of the issues were still TODO, 21% WIP and 36% DONE.

## The Road Ahead

We are very happy we were given the opportunity to work with and have
our assumptions and code reviewed and tested by security experts. Early
on we decided that we want to benefit from the findings as much as
possible. That's why we created a [project
board](https://github.com/orgs/fluxcd/projects/5) and added
a review of it as a standing agenda item in our weekly dev meetings.

> "The Flux team also created a public and easy to track dashboard
> showing all of the work we\'ve done together and is a fantastic
> example of good issue-tracking and remediation."
>
> \-- Derek Zimmer, President and Executive Director,
> [OSTIF](https://ostif.org/)

### Growing the team

If you are interested in contributing to this, we are very much looking
forward to working with you. We welcome contributions in helping resolve
issues of the road, additional comments on our security posture and also
welcome contributions in the form of extending our fuzzing
infrastructure. Finally, if you have any additional security feedback,
please come and talk to us.

We are working full steam on the [Flux Roadmap](/roadmap/), just recently got
more maintainers involved and continue to listen to feedback.

Again we would like to thank the Cloud Native Computing Foundation for
sponsoring the audit, the Open Source Technology Improvement Fund for
the coordination and ADA Logics for the careful review and advice during
the audit period.

We are happy and proud to be part of this community!
