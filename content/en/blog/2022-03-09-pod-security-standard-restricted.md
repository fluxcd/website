---
author: dholbach
date: 2022-03-09 12:30:00+00:00
title: 'Security: Using Pod Security Standard "restricted"'
description: pod security standards is a recent addition to Kubernetes, coming to replace pod security policies. Alongside seccomp, it provides greater isolation levels to workloads. Read up on how we moved all Flux controllers to 'restricted' mode and how that's going to keep you safer.
url: /blog/2022/03/security-pod-security-standard-restricted/
tags: [security]
---


Next up in our [blog series about Flux
Security](/tags/security/) is how we moved
to Pod Security Standard "restricted", all the background info you need
to know and how that makes things safer for you.

[Since version 0.26 of
Flux](/blog/2022/01/january-update/#security-news)
we are applying

> \[..\] the [restricted pod security
> standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)
> to all controllers. In practice this means:
>
> - all Linux capabilities were dropped
> - the root filesystem was set to read-only
> - the `seccomp` profile was set to the runtime default
> - run as non-root was enabled
> - the filesystem group was set to 1337
> - the user and group ID was set to 65534
>
> Flux also enables the Seccomp runtime default across all controllers.
> Why is this important? Well, the default `seccomp` profile blocks key
> system calls that can be used maliciously, for example to break out of
> the container isolation. The recently disclosed [kernel vulnerability
> CVE-2022-0185](https://blog.aquasec.com/cve-2022-0185-linux-kernel-container-escape-in-kubernetes)
> is a good example of that.

## Pod Security Standards definition

Kubernetes defined three policies in its Pod Security Standards. They
range from

- **Privileged**: This does not place any restrictions on the workload
  at all. The idea being that this can be used for system- and
  infrastructure-level workloads which are managed by privileged and
  trusted users only.
- **Baseline**: This policy comes with some restrictions. It aims to
  guard against known privilege escalations while still making it
  easy to adopt and use it by keeping a certain level of
  compatibility with most workloads.
- **Restricted**: Inheriting all the restrictions from *Baseline*, it
  enforces additional limitations, thus follows hardening best
  practices by increasing the isolation levels the workload is
  exposed to.

We are very pleased that all Flux controllers were moved to
*Restricted*, as that offers the highest level of security for you.

We recommend checking out the [Upstream Kubernetes documentation on Pod
Security
Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
as it gives a generally good overview of all the security features
enabled. In addition to that you can see which restrictions were added
as part of which Kubernetes release, meaning that with every Kubernetes
release, you will benefit from new Upstream Kubernetes security
improvements automatically.

{{% note %}}
As of v1.24 Kubernetes still runs all workloads with `seccomp` in
`unconfined` mode, in other words, disabled. On the other hand, Docker
has `seccomp` enabled by default for years now.

There are discussions to change the Kubernetes default on v1.25, and have all
workloads set to `RuntimeDefault` unless opted-out. This would be based on
`SeccompDefault` [feature
gate](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
being enabled from that version onwards.
{{% /note %}}

{{% note %}}
If you are an OpenShift user, you might run into [this
issue](https://github.com/fluxcd/source-controller/issues/582)
([related upstream
report](https://github.com/openshift/cluster-kube-apiserver-operator/issues/1325)).
The work-around right now is to remove the seccomp profile as
described in [these instructions](/flux/use-cases/openshift/).
{{% /note %}}

## `seccomp` and `RuntimeDefault`

Seccomp is short for "Secure Computing". It refers to a facility in the
Linux kernel which can limit the number of system calls available to a
given process. Right now there are around 300+ system calls available,
e.g. `read` to read from a file descriptor or `chmod` to change the
permissions of a file. The more syscalls you block, the more secure your
application, as a rogue process will only be able to do what you
specified.

In its first inception `seccomp` was introduced into Linux in 2005, to
Docker in version 1.10 (Feb 2016) and to Kubernetes in version 1.3 (Jul
2016). So while the technology has been around for a while and you could
handcraft your own `seccomp` profiles, the challenge has always been
striking the right balance: if you are too generous in your filter, it
won't guard against malware effectively -- if you are too strict, your
application might not work.

All container runtimes come with a default seccomp profile. [Docker
Desktop for
example](https://github.com/moby/moby/blob/master/profiles/seccomp/default.json)
blocks around 44 system calls. In Kubernetes you can enable the seccomp
profile RuntimeDefault for your pod like so:

```yaml
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

All Flux controllers have this implemented as well now!

By adopting both changes, we further restrict the permissions that Flux
requires in order to operate. This, alongside other changes we are working
on, translate in a decreased attack surface which may reduce the impact of
eventual CVEs that may surface in our code base - or our supply chain.

## Further reading

If you would like to understand the concepts in this blog post better,
you might want to check out these blog posts (in addition to the docs
referred to above):

- [Seccomp in Kubernetes --- Part I: 7 things you should know before
  you even start! \| by Paulo Gomes](https://itnext.io/seccomp-in-kubernetes-part-i-7-things-you-should-know-before-you-even-start-97502ad6b6d6)
- [How to enable Kubernetes container RuntimeDefault seccomp profile
  for all workloads \| by Lachlan Evenson](https://medium.com/@LachlanEvenson/how-to-enable-kubernetes-container-runtimedefault-seccomp-profile-for-all-workloads-6795624fcbcc)
- [Enable seccomp for all workloads with a new v1.22 alpha feature \|
  Kubernetes](https://kubernetes.io/blog/2021/08/25/seccomp-default/)
- [Restrict a Container\'s Syscalls with seccomp \| Kubernetes
  Documentation](https://kubernetes.io/docs/tutorials/security/seccomp)

## Talk to us

We love feedback, questions and ideas, so please let us know your
personal use-cases today. Ask us if you have any questions and please

- join our [upcoming dev meetings](/community/#meetings)
- find us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- add yourself [as an adopter](/adopters/) if you haven't already

See you around!
