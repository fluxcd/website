---
author: makkes
date: 2023-11-09 00:00:00+00:00
title: Second Flux Security Audit has concluded
description: Flux just went through its second CNCF-funded Security Audit. Here we publicly release and discuss the report.
url: /blog/2023/11/flux-security-audit
aliases: [/blog/2023-11-09-flux-security-audit/]
tags: [security, announcement]
resources:
- src: "**.png"
  title: "Image #:counter"
---

Precisely 2 years after [performing our first security Audit](/blog/2021/11/flux-security-audit/),
we had the chance to put Flux through a second audit this year, again
facilitated by the CNCF and the [Open Source Technology Improvement Fund](https://ostif.org/).
[Trail of Bits](https://www.trailofbits.com/) partnered with us this time
to make Flux even more secure. Flux passed the "General Availability"
milestone earlier this year and the focus was on the features shipped in
the Flux GA release.

The Flux maintainers and community are very grateful for the work put
into this by everyone and the opportunity to grow and improve as a
project. Thanks to Trail of Bits, notably Maciej Domański, Sam Alws, Sam Greenup and Jeff Braswell, who have always been extremely responsive during the process.

![TOB, CNCF, OSTIF](featured-image.png)

## No new CVEs

Good news first: No new CVEs have been published for Flux in response to
this second audit. Trail of Bits highlight that they found Flux was "well
structured and generally written defensively" and the "audit uncovered
only low- and informational-severity findings", 10 in total. 8 of the
discovered issues have been fixed as of publication of this announcement. From the remaining two issues to be fixed, one is in the process of being resolved and for the other one we have decided to accept the very low risk due to reasons mentioned in the report.

The assessment was kicked off with a list of 23 questions to be answered,
circling around potential data leaks, security documentation, access
control or denial of service vulnerabilities. Since the focus was on the
GA components, the following parts of Flux have been put under scrutiny:

- source-controller
- kustomize-controller
- notification-controller
- Flux CLI
- The `pkg` library, and `git/gogit/fs` in particular

## Details on the discovered issues

You will find the full report [here](/flux-security-report-with-review-2023.pdf). The following table shows all the findings together with links to the pull requests fixing them:

Issue | Severity | Fix
----- | -------- | ---
1: SetExpiration does not set the expiration for the given key | low | [source-controller#1185](https://github.com/fluxcd/source-controller/pull/1185)
2: Inappropriate string trimming function |informational | [notification-controller#590](https://github.com/fluxcd/notification-controller/pull/590)
3: Go’s default HTTP client uses a shared value that can be modified by other components | low | [flux2#4182](https://github.com/fluxcd/flux2/pull/4182)
4: Unhandled error value | informational | [flux2#4181](https://github.com/fluxcd/flux2/pull/4181)
5: Potential implicit memory aliasing in for loops | informational | [source-controller#1257](https://github.com/fluxcd/source-controller/pull/1257), [notification-controller#627](https://github.com/fluxcd/notification-controller/pull/627), [flux2#4329](https://github.com/fluxcd/flux2/pull/4329)
6: Directories created via os.MkdirAll are not checked for permissions | informational | n/a
7: Directories and files created with overly lenient permissions | informational | [pkg#663](https://github.com/fluxcd/pkg/pull/663), [pkg#681](https://github.com/fluxcd/pkg/pull/681), [source-controller#1276](https://github.com/fluxcd/source-controller/pull/1276), [kustomize-controller#1005](https://github.com/fluxcd/kustomize-controller/pull/1005), [flux2#4380](https://github.com/fluxcd/flux2/pull/4380)
8: No restriction on minimum SSH RSA public key bit size | informational | [flux2#4177](https://github.com/fluxcd/flux2/pull/4177)
9: Flux macOS release binary susceptible to dylib injection | low | in progress
10: Path traversal in SecureJoin implementation | undetermined | [pkg#650](https://github.com/fluxcd/pkg/pull/650), [go-git/go-billy#31](https://github.com/go-git/go-billy/pull/31), [go-git/go-billy#34](https://github.com/go-git/go-billy/pull/34)

In addition to the pull requests linked above we also enabled security
and quality CI checks through CodeQL via [flux2#4121](https://github.com/fluxcd/flux2/issues/4121) to prevent any avoidable regressions.

## Conclusion and next steps

From our perspective as Flux maintainers,  2 years feel like a lifetime. We added lots of new features and fixed even more bugs in that timeframe. That's why we
are particularly grateful that CNCF and OSTIF gave us the opportunity to
let a team of security experts assess Flux another time. We are proud
of having been able to learn from the first assessment and kept on making
Flux more and more secure over these past 2 years, leading to only low-
and informational-severity security findings within the GA components of
Flux.

Our [next milestone](https://fluxcd.io/roadmap/#flux-helm-ga-q3-2023) is the general availability of Flux’s Helm features and the subsequent general availability of the remaining Flux components. If you are interested in contributing to this, we are very much looking forward to working with you. We welcome contributions in helping resolve issues of the road, additional comments on our security posture and also
welcome contributions in the form of extending our fuzzing
infrastructure. Finally, if you have any additional security feedback,
please come and talk to us.

Again we would like to thank the Cloud Native Computing Foundation for
sponsoring the audit, the Open Source Technology Improvement Fund for
the coordination and Trail of Bits for the careful review and advice
during the audit period.

We are happy and proud to be part of this community!



