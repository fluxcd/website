---
author: dholbach
date: 2022-03-25 09:30:00+00:00
title: 'Flux puts the Git into GitOps'
description: Flux integrates very tightly with all relevant APIs and SDKs. For us to provide the best possible Git support to bring you GitOps, shelling out to Git is not an option. Find out why in this blog post.
url: /blog/2022/03/flux-puts-the-git-into-gitops/
---

Ever since the rewrite of Flux as a set of focused controllers, it has
become clearer what each of its functions and capabilities are. The
aptly named controllers carry in their name what they are responsible
for and which data or tooling they interact with, so that is, e.g.
`source`, `kustomize`, `image-automation`, `notification`, `helm`,
etc.

![Overview Flux controllers](/img/diagrams/gitops-toolkit.png)

If you wanted to string a proof-of-concept for a GitOps tool together, a
naïve solution could be to just shell out to various tools like `curl`,
`git`, `kubectl` and `helm`. While that might feel intuitive at first (since
it so closely resembles one's manual workflow behind the keyboard) and
might be quick and fundamentally functional, it comes at a
big cost in the subsequent refinement stages: adequately catching
errors, providing detailed status information, security considerations,
mismatches between command line tools and infrastructure implementation,
API and CLI versions, etc.

In the course of the last five years since the start of the Flux
project, we have seen all of the above and more. Because other projects
made those mistakes, or because we did.

Let's drill a bit deeper into why we put so much effort into integrating
as tightly with given tooling APIs and SDKs as possible.

## Why we are not using the Git CLI

![Git logo](featured-git.png)

Without Git there is no GitOps, so we obviously want to support all Git
providers, all the edge cases, all the different ways things can be set
up and all the Git operations we need. Obvious interactions with Git are
when we perform clone and push operations on remote Git repositories,
for example.

Using a CLI for any code-path should be a last resort - if at all. It is
a design principle for the Flux controllers not to do this. We avoid an
entire class of vulnerabilities: command injection.

Another big reason back when we started working on `source-controller`
for dropping the Git CLI was multi-tenancy. The Git CLI wants the SSH and
PGP keys on disk while we wanted them to be loaded from memory to isolate
the tenants secrets without having to write them on disk and risk being
vulnerable to directory traversal attacks.

All in all we did choose not having to rely on the Git binary being present,
instead we link statically against a known-good and sufficiently well-tested
version. More on that below.

## Why do we have support for multiple Git implementations

We started out using [go-git](https://github.com/go-git/go-git) for
all Git operations, as it is an implementation of the Git protocol
written entirely in Go. When we wanted to support Azure DevOps and saw
that support for `multi_ack` and `multi_ack_detailed` wasn't included
in `go-git`, we started making use of
[git2go](https://github.com/libgit2/git2go) in addition. It is the Go
bindings of [the libgit2 library](https://libgit2.org/) and has greater
support for more complex capabilities in the git wire protocol, including
[git protocol version 2](https://git-scm.com/docs/protocol-v2).
Unfortunately `git2go` does not support shallow clones or Git submodules.
The newly added support for commit signing with SSH keys is also not
supported by our implementations at present.

While the above might sound like petty implementation details, we had to
learn ourselves that each Git implementation has its own set of
shortcomings. Things which "just work" in the Git CLI, any of the
implementations get subtly wrong, as they work on the ["plumbing"
level](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)
of Git. In the end we chose to make `gitImplementation` a [configurable
setting](/flux/components/source/gitrepositories/#git-implementation).

Just to illustrate what happens when you try to do things just right,
here's a couple of pieces of work we needed to get done along
the way:

- we had to add support for e.g. verifying `known_hosts` files for SSH
  connections
- when connecting over SSH, we received SHA1 and MD5 fingerprints of
  the returned public key from the server and not the key itself,
  which made `known_hosts` verification a little harder
- changes on `libgit2` would [break the way that known hosts used to
  work](https://github.com/fluxcd/source-controller/commit/9479d04779ccb7fc44b972cde23cb9a6c052f445)
- Making various kinds of SSH key types work, e.g. support for
  `ECDSA*` added as part of `libgit2 >= 1.2.0`, `ED25519` as part of
  `libgit2 >= 1.3.0`.
- we needed to start verifying PGP signatures

## Tracking upstream developments in Git

As Git has become ubiquitous and virtually all of the world's software
development depends on Git, it still is in active development. Constant
improvements affect features, efficiency, configurability and better
security. Of course we want to pass this all down to our users: more
efficient download makes a huge difference, support for Git Submodules
enables new use-cases, support for more GPG verification or new SSH key
formats adds additional security and when new features are rolled out in
Git providers, we need to support them in Flux too.

Integrating these changes into Flux unfortunately isn't as easy as it
sounds. One part of the dependency chain for
[git2go](https://github.com/libgit2/git2go) goes:

```mermaid
flowchart LR
libgit2 --> libssh2 --> OpenSSL
```

So that's [libgit2](https://libgit2.org/),
[libssh2](https://libssh2.org) (to enable the SSH transport) and
[OpenSSL](https://www.openssl.org/). As Linux vendors often take a very
conservative approach to bringing new software releases to stable
releases, we were unfortunately pushed to
[building these dependencies ourselves](https://github.com/fluxcd/golang-with-libgit2#rationale).
In addition to that, these libraries have quite a few configuration
options that can only be set at build time and unfortunately the
`openssl`/`libssh2` packages of different Linux distributions act in
[slightly different
ways](https://github.com/fluxcd/golang-with-libgit2/blob/libgit2-1.3.0/hack/Makefile#L63-L69).
This created a yet different problem: the versions we shipped on the
containers could behave in different ways when we were developing on our
Mac/Linux machines. This forced us to cross-compile statically built
libraries that we can simply download at both development time or
statically linking them into the final binary we create when releasing
our controllers.

We decided to build the libraries for the AMD64, ARM64 and ARMv7
architectures and link them statically, which was a prerequisite for us
to [enable
fuzzing](/blog/2022/02/security-more-confidence-through-fuzzing/)
for all Flux controllers. Getting this all up and running for every
upstream release and making sure it's all covered nicely with tests is a
challenge and an area of work we invested quite a lot of time in.

## What's next in Git things?

`libgit2` does not expose concepts to allow users to set timeouts for
network operations, meaning that most git operations could hang
indefinitely in specific circumstances. This would result in specific
`GitRepository` objects getting stuck and stop updating until the
controllers get restarted - Users reported this for both the
image-automation and source controllers in the past 6 months.

We had a few challenges getting traction making changes upstream to fix
similar issues, so to avoid delaying a fix or forking the dependency, we
decided to add experimental support for Go managed transports, which means
we can enforce that network operations won't take more than a given
amount of time to complete, but without requiring any changes upstream.

This is [part of Flux 0.28](https://github.com/fluxcd/flux2/releases/tag/v0.28.0)
and can be enabled by adding an environment `EXPERIMENTAL_GIT_TRANSPORT=true`
in both `source` and `image-automation` controllers.

This will give us more control over the transport with Go native
transport using the `libgit2` smart transport support. Read the
[source-controller
changelog](https://github.com/fluxcd/source-controller/blob/main/CHANGELOG.md#experimental-managed-transport-for-libgit2-git-implementation)
for more information.

If you want to enable this automatically, just add the following to
your `kustomization.yaml`:

```yaml
patches:
- patch: |
    - op: add
      path: /spec/template/spec/containers/0/env/0
      value:
        name: EXPERIMENTAL_GIT_TRANSPORT
        value: "true"
  target:
    kind: Deployment
    name: "(source-controller|image-automation-controller)"
```

Support for sha256 hashes: Git CLI supports it since 2.29, however all major Git
service providers, such as GitLab and GitHub, are yet to make some progress on 
this front.
Upstream, libgit2 is starting to pave the way for that support on
[v1.4.0](https://github.com/libgit2/libgit2/releases/tag/v1.4.0),
we will continue to watch this space so we can support Flux users as the industry
moves on from SHA1.

After this strong focus on stability in the last months, we are now
going to take a look at how we can optimise our git implementation to
reduce resource consumption and network traffic across git reconciliations.

## Conclusion

Flux doesn't shell out to binaries like `git`, `helm` or `kubectl`,
because we deem it too error-prone and we would miss big opportunities
to bring you the best developer experience and the most accurate information
on every step along the way. This way we offer more control to you. As you
might have gathered from the amount of additional work this all means for
us, we take the "Git" in "GitOps" very seriously.

## Talk to us

We love feedback, questions and ideas, so please let us know your
personal use-cases today. Ask us if you have any questions and please

- join our [upcoming dev meetings](/community/#meetings)
- find us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- add yourself [as an adopter](/adopters/) if you haven't already

See you around!
