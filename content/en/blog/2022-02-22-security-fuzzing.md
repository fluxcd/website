---
author: dholbach
date: 2022-02-22 8:30:00+00:00
title: 'Security: More confidence through Fuzzing'
description: ADA Logics helped us moving to Fuzzing as part of their security audit. We finally implemented this for all Flux controllers. Learn here how this keeps you safer.
url: /blog/2022/02/security-more-confidence-through-fuzzing/
tags: [security]
---

Next up in our blog series about Flux Security is how we implemented
fuzzing in Flux and its controllers and how that makes things safer for
you.

[Wikipedia explains Fuzzing](https://en.wikipedia.org/wiki/Fuzzing)
like so:

> **Fuzzing** or **fuzz testing** is an automated software testing
> technique that involves providing invalid, unexpected, or random data
> as inputs to a computer program. The program is then monitored for
> exceptions such as crashes, failing built-in code assertions, or
> potential memory leaks. Typically, fuzzers are used to test programs
> that take structured inputs. This structure is specified, e.g., in a
> file format or protocol and distinguishes valid from invalid input. An
> effective fuzzer generates semi-valid inputs that are \"valid enough\"
> in that they are not directly rejected by the parser, but do create
> unexpected behaviors deeper in the program and are \"invalid enough\"
> to expose corner cases that have not been properly dealt with.

We already have quite a good coverage of unit and end-to-end tests
across the controllers. Adding fuzzing to the mix will further extend
the scope of tests to scenarios and payloads not previously covered.
Together with the fuzzing that's already being done within the
Kubernetes repositories, e.g. `kubernetes`, `client-go` and
`apimachinery` we feel ever more confident in our code.

We are happy to share that since the 0.27 release of Flux all Flux
controllers and libraries are now tested by [Google's continuous
fuzzing for open source software](https://github.com/google/oss-fuzz).

## How we got here

When we [announced the results of the security
audit](/blog/2021/11/flux-security-audit/#flux-coming-to-oss-fuzz)
back in November, we already shared that the team at [ADA
Logics](https://adalogics.com/) had helped put together an initial
implementation of Fuzzing for some of the Flux controllers. In this
first inception three issues were already found (1x slice
out-of-bounds, 2x nil-dereference), and immediately fixed.
Naturally we were very interested in merging the fuzzing integration.

In order for us to fully land the fuzzers, we needed to make some
architectural changes to the build process, especially for the
controllers that rely on C bindings to `libgit2`, such as
`source-controller` and `image-automation-controller`, which are now
statically built. In addition to that, we extended the scope of the
fuzzers considerably. If you take a look at the related [pull request
for
notification-controller](https://github.com/fluxcd/notification-controller/pull/306)
you get a good idea of what this all entailed, e.g. fuzzing for all
notifiers.

Fuzzers are now run for every commit which lands in the Flux controllers
and libraries.

Thanks again ADA Logics for contributing and to everyone else who helped
integrate this! We are also very grateful to Google and
[OpenSSF](https://openssf.org/) who provide and maintain the required
infrastructure.

## What's next

As Go will see built-in Fuzz support in 1.18, we were very interested
in structuring everything closely to the new format, so that the
transition from [dvyukov/go-fuzz](https://github.com/dvyukov/go-fuzz)
(which is currently being used) goes smoothly. (We can recommend [Jay
Conrod's blog
post](https://jayconrod.com/posts/123/internals-of-go-s-new-fuzzing-system)
about the Internals of Go's new fuzzing system, if you are curious!)

The move of Flux to go native fuzzing is being tracked in [this
issue](https://github.com/fluxcd/flux2/issues/2417). We
also hope to add new fuzzers soon, so if you want to contribute there:
come and find us on Slack! It's an easy way to get to know and extend
the Flux codebase.

This is just one more measure we are taking to keep you more secure.

## Talk to us

We love feedback, questions and ideas, so please let us know your
personal use-cases today. Ask us if you have any questions and please

- join our [upcoming dev meetings](/community/#meetings)
- find us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- add yourself [as an adopter](/adopters/) if you haven't already

See you around!
