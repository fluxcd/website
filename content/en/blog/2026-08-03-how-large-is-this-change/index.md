---
author: Santhosh Kumar Somarapu
date: 2026-08-03 12:00:00+00:00
title: "How large is this change? The question a GitOps pipeline never asks"
description: "Flux will gladly tell you whether a change is well-formed. If a typo tells it to delete your entire production namespace, it will not ask twice."
url: /blog/2026/08/how-large-is-this-change/
tags: [ecosystem]
---

There is an [issue open in the Flux tracker](https://github.com/fluxcd/flux2/issues/5512) that
describes a bad afternoon. Its author pointed a `FluxInstance` at a directory that turned out to be
empty, and Flux, in their words, "gleefully proceeded to delete everything it was managing before."

Read the mechanics and nothing malfunctioned. Git served the source. The Kustomization built. The
diff was computed correctly against live state. The apply succeeded, resource by resource, exactly
as instructed. There is no component in that chain you would file a bug against.

That issue asks for configurable safeguards, and it already contains most of the right answer — the
observation that a Kustomization dropping from 100 objects to 1 is almost certainly a mistake, and
the suggestion that an expected decrease could be signalled up front in a commit message or an
annotation. It has been open since September 2025.

I want to make the case for why that request is more general than it looks, what it costs to build
today, and why the place it eventually belongs is inside the reconciler rather than in anybody's CI.

## Pruning is not the bug

It is tempting to look at that outcome and conclude that garbage collection is too dangerous. It
isn't. It is the whole point.

The [Flux docs](https://fluxcd.io/flux/components/kustomize/kustomizations/#prune) are explicit:
garbage collection means that "the Kubernetes objects that were previously applied on the cluster
but are missing from the current source revision, are removed from the cluster automatically." If a
resource is no longer declared, it should not survive. A reconciler that quietly left orphans behind
would be a worse tool, and every one of us would file *that* as a bug.

So the desired state became "nothing," and Flux converged to nothing. It did its job. The gap is
that nowhere in the pipeline did anything ask whether converging to nothing was a plausible thing
to want.

## Reconcilers make this sharper than push tooling

Every configuration system has some version of this problem, but continuous reconciliation gives it
a particular edge — and not the one usually cited. It is tempting to say that push pipelines have a
human watching and reconcilers do not, but that is no longer true. A GitHub Action running `kubectl
apply` on merge is exactly as unattended as a reconciliation loop.

The real difference is the scope of what executes. A push pipeline applies *files*. Point it at a
directory that has accidentally become empty and there is nothing to apply — the job often fails
outright for want of input, and the worst case is usually that nothing happens. A reconciler is not
applying files; it is managing the state of everything the source describes. An empty directory is
not an absence of instructions to it. It is a complete and valid instruction that the desired state
is nothing, and it will actively issue deletions to reach it.

Put another way: the push pipeline's blast radius is bounded by what it was handed, while the
reconciler's is bounded by what it owns. That inversion is the price of convergence, and it is
usually worth paying — but it means an empty input is a much more dangerous thing to hand a
reconciler than a pipeline.

Reconciliation also repairs. If the removal is corrected in Git a few minutes later, the objects
come back — but recreated, not restored. Anything the cluster held that was not in the manifests is
simply gone.

## What Flux checks today

Flux is not short of safety machinery. It's worth laying out what is actually there:

- **`prune`** decides whether removal happens at all.
- **`wait`** performs health checks for all reconciled resources; when true,
  [`healthChecks` is ignored](https://fluxcd.io/flux/components/kustomize/kustomizations/#health-checks).
- **`healthChecks`** watches a named list of resources for readiness and rollout status.
- **`dependsOn`** holds a Kustomization until the ones it names are `Ready`.
- **`suspend`** stops new revisions being applied and pauses drift correction.
- **`timeout`**, **`retryInterval`** and **`force`** handle the mechanics around all of it.

Group those by the question they answer and a pattern falls out. Is this well-formed? Is the
controller permitted to do it? In what order? Is the result healthy afterwards?

Nothing in that list asks how big the change is. And the two that come closest — `wait` and
`healthChecks` — evaluate *after* the apply. On a prune-everything event that is precisely when
there is nothing left to check. The Kustomization can go `Ready` with an empty inventory, because
an empty inventory is trivially healthy.

## The tooling is closer than it looks

Here is the part I find genuinely encouraging: Flux already computes the thing we need.

[`flux diff kustomization`](https://fluxcd.io/flux/cmd/flux_diff_kustomization/) builds the
Kustomization, runs a server-side dry-run, and prints the difference against live state:

```sh
flux diff kustomization apps --path ./clusters/prod/apps
```

Remove two resources from a reconciled Kustomization's source and it tells you precisely what it
intends to do:

```text
► Service/default/podinfo deleted
► HorizontalPodAutoscaler/default/podinfo deleted
⚠️ identified at least one change, exiting with non-zero exit code
```

Its exit codes are `0` for no differences, `1` for differences found, and greater than `1` for an
error. So the command already distinguishes three states: nothing changed, something changed, the
tooling broke.

What it does not distinguish is a small change from a catastrophic one. Removing one obsolete
ConfigMap and removing every resource in the namespace are both, to that exit code, a `1`.

The diff is right there. Nobody is measuring it.

## Two questions that get conflated

The reason magnitude checks tend to fail in practice is that teams try to answer one question when
there are really two.

**Is this change large?** This is computable. It falls out of the diff, before anything reaches the
cluster. Count of resources removed, share of the managed inventory, whether an inventory goes to
zero. This is the "100 objects down to 1" heuristic from the issue, stated generally.

**Was a large change expected?** This is not computable by anything. Decommissioning a service
removes everything in its namespace, and that is a perfectly good afternoon's work. Only the author
knows, and the only way to find out is to make them say so — which is exactly why the issue reaches
for a commit message or an annotation. The declaration has to come from outside the diff, because
the diff cannot contain it.

A guardrail that trips when — and only when — those two disagree stays quiet during normal
operation. That matters more than it sounds. A guardrail that fires on legitimate changes gets
switched off by the team it was built to protect, usually within a fortnight, usually with a
justified complaint attached. Quietness isn't a nicety. It's a correctness requirement, because a
disabled guardrail protects nothing.

## Wiring it into CI

You may not have to build this yourself. [`flux-local`](https://github.com/allenporter/flux-local)
already does diff-in-CI for Flux repositories and was recommended in that same issue thread; if it
fits your setup, use it. What follows is the smallest thing that demonstrates the idea, so that the
mechanism is visible rather than buried in a tool.

The check can live in your pull request pipeline, before a merge ever reaches the cluster:

```sh
#!/usr/bin/env bash
set -uo pipefail

flux diff kustomization apps \
  --path ./clusters/prod/apps > /tmp/flux.diff
rc=$?

# Anything above 1 is a tooling failure, not a verdict.
[ "$rc" -gt 1 ] && exit "$rc"

# Flux prints one "► <object> deleted" line per removal.
# Flux suppresses colour when stdout is not a terminal; the strip is
# there for CI runners that allocate one.
removed=$(sed $'s/\033\\[[0-9;]*m//g' /tmp/flux.diff | grep -c ' deleted$')

if [ "$removed" -gt 5 ] &&
   ! git log -1 --format=%B | grep -q 'flux: intentional removal'; then
  echo "This change removes ${removed} resources."
  echo "If that is deliberate, add 'flux: intentional removal' to the commit message."
  exit 1
fi
```

The threshold is not the interesting part, and you should expect to tune it per Kustomization. The
commit-message marker is the interesting part. It is the out-of-band declaration — the mechanism by
which the author's intent enters a pipeline that otherwise only sees YAML. It costs one line when
you mean it, and it fails the build when you don't.

Two caveats, because I would rather state them than have you discover them.

**This parses human-readable output, and that is brittle.** I am counting lines from a CLI meant
for people to read. It works today — the marker comes from a single `Sprintf` in the CLI's diff
path — but it is one formatting change away from silently counting zero, which is the worst
possible failure for a guardrail. A `--output=json` mode on `flux diff` would turn this from a
scrape into an interface, and that is worth asking for on its own.

**And CI is the wrong place for it, in a way worth being precise about.** `flux diff` compares your
branch against the live cluster *at the moment CI runs*. A pull request that sits open for three
days is checked against a cluster that no longer exists by the time it merges. Resources may have
been added or removed in between, so the removal count you approved is not the removal count that
gets applied. The check is honest about the cluster it saw and silent about the one it didn't.

That gap does not have a fix in CI, and it is the strongest argument I know for the check living
inside the reconciler — evaluated against real live state, in the moment before the apply, where
the number cannot go stale.

## What else helps today

None of this needs new features.

**Split large Kustomizations.** The blast radius of a mistake is the inventory of a single
Kustomization, so that inventory is a design decision. Several narrow ones bound the damage in a way
one broad one cannot.

**Set `prune: false` where an empty inventory is never legitimate.** Be clear about what this costs,
because it is not free: with pruning off, every *intentional* removal leaves an orphan behind. Delete
an obsolete ConfigMap from Git and it stays in the cluster, unmanaged and unnoticed, until someone
removes it by hand. You are trading the risk of catastrophic deletion for a steady accrual of
technical debt. For the Kustomizations holding your cluster's foundations that is usually the right
trade, and it is the wrong one nearly everywhere else.

**Know what is managed before it changes.** `flux tree kustomization` will show you the inventory. It
is worth looking at the number occasionally; most people have never seen it.

**Be honest about what health checks cover.** `wait` and `healthChecks` are worth having and they
will not catch this. Different failure, different check.

## The gap is not Flux's alone

This shape recurs wherever configuration is applied automatically, and one neighbouring ecosystem
has already solved it.

Terraform and OpenTofu users do not merge a plan on trust. They render it, and then evaluate it —
commonly with [Open Policy Agent](https://www.openpolicyagent.org/) — against rules like *this plan
destroys more than N resources, so fail the pipeline*. Policy evaluation of a rendered plan is a
completely ordinary step in that world, and the reason it exists is that people learned the hard way
what an unreviewed destroy count costs.

GitOps has the plan. `flux diff` renders it. What is missing is the phase that comes next: somewhere
to evaluate the plan before it is applied, expressed as policy rather than as a shell script each
team writes for itself.

Taken together these point at something systemic rather than local. Declarative configuration
systems specify state *delivery* in meticulous detail and omit state *transition* safety almost
entirely — they are precise about what the end state should be and silent about how to get there
without harm.

That holds outside the cluster too. The OpenTelemetry OpAMP protocol
manages configuration for agent fleets, and its specification covers delivery and agent health
reporting in real detail while saying nothing about staged rollout, or about halting when part of
the fleet reports unhealthy. The signals a gate would need are already in the protocol. I
[raised that with the OpAMP SIG](https://github.com/open-telemetry/opamp-spec/issues/384) recently.

Different projects, same missing question.

## Where this could go

Everything above is something you can build outside Flux, which is where I would start on Monday.
But both caveats point the same way. Scraping human-readable output is brittle, and a check that
runs in CI is checking a cluster that may not be the one it lands on.

So there are two asks here, and they are different sizes. The small one is structured output from
`flux diff`, which would turn every guardrail anyone builds from a scrape into an interface. The
larger one is a threshold Flux understands natively.

Concretely, that could be a field or two on the Kustomization spec:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  prune: true
  # Refuse to reconcile if a single revision would remove more than
  # this many objects, or this share of the managed inventory.
  maxDeletions: 5
  maxDeletionPercentage: 10
```

with an annotation on the source revision — or a marker in the commit — to override it when the
removal is intended. The reconciler already computes the inventory delta before it applies anything,
so the number the check needs is in hand at exactly the right moment, evaluated against live state
rather than against whatever the cluster looked like when CI ran. That is the one place the number
cannot be stale.

Issue [#5512](https://github.com/fluxcd/flux2/issues/5512) has been open since September 2025 and no
maintainer has weighed in yet. If there is appetite for it, I am willing to write the design up as
an RFC — and credit for the original request belongs to whoever filed it.
