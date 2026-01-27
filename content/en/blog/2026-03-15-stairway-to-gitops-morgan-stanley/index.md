---
author: Flux Team
date: 2026-03-15 12:00:00+00:00
title: "Stairway to GitOps: Scaling Flux at Morgan Stanley"
description: "Reflecting on Morgan Stanley's journey to production GitOps with Flux, presented at FluxCon NA 2025."
url: /blog/2026/03/stairway-to-gitops-morgan-stanley/
tags: [fluxcon, user-story, enterprise, scale]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

One of the things we love most about this community is hearing how you take Flux and run with it - truly solving problems for teams at scale. At our inaugural FluxCon NA, **Tiffany Wang** and **Simon Bourassa** from **Morgan Stanley** gave us a glimpse of their Flux environment.

Their talk, **"Stairway to GitOps,"** walked us through a five-year journey from push-based pipelines to a self-service GitOps platform managing over 500 clusters. Hearing the core principles of Flux - **Lean, Performant, Extensible, and Secure** - validated by end-users at this scale matters a lot to us as maintainers. We think their lessons are worth sharing with all of you.

![Flux maintainers together at FluxCon NA 2025](https://fluxcd.io/img/fluxcon-na-25/maintainers-5.png)
*Matheus Pimenta cracking a joke with the Flux team together at FluxCon NA 2025 - (Moments with all of these people in-person are rare!)*

## The Early Days: Pushing Limits

Like many teams, Morgan Stanley started with traditional push-based CI/CD pipelines. App teams used tools like Helm to push manifests directly to clusters. While functional for initial deployments, challenges emerged as they scaled. Familiar pain points crept in:

*   **Configuration Drift:** Without an agent continuously reconciling state, clusters drifted from the source of truth in Git. Manual changes and failed deployments left systems in an unknown state.
*   **Fragile Recovery:** Cluster rebuilds required heavy coordination. The platform team could restore infrastructure, but application teams had to manually redeploy their workloads. (Not a great place to be at 2 AM in another team's timezone)

At "Step 0" of their Stairway to GitOps, they realized they needed to decouple delivery from the pipeline and embrace continuous reconciliation.

## Step 1: Security and Self-Service

In a highly regulated financial environment, security isn't optional. The team chose Flux to fit their strict multi-tenancy model.

Morgan Stanley leveraged **Flux's service account impersonation** and native Kubernetes RBAC to enforce least-privilege access. Controllers reconciling manifests for one team had zero visibility into another team's resources. Granular, secure multi-tenancy is a first priority part of Flux's design, so this is the golden path, but implementing it always involves deciding what teams get what permissions, and they put in that work.

To streamline adoption, they built a **self-service onboarding platform**. Instead of requiring developers to manage low-level Kubernetes details, they created tooling that:
1.  Automated entitlement checks and change control processes.
2.  Registered services in their CMDB.
3.  "Primed" the target namespace with the necessary Flux `GitRepository` and `Kustomization` resources.
4.  Scaffolded a ready-to-use application repository.

This approach demonstrates Flux's extensibility. Flux can serve as the glue between systems. Developers interact with their normal tooling, while company specific systems like CMDB's (which likely predate Kubernetes adoption at all) integrate smoothly into the GitOps flow.

## Step 2: Operating at Scale

As adoption grew, so did the deployment footprint. Tiffany shared some numbers from their environment:

> *"And now we have over 500 clusters, over 2,000 nodes, over 100,000 containers, and tens of thousands of Flux resources."* (13:34)

Operating at this magnitude brings challenges around performance. The team shared how they tuned Flux to handle this load without overwhelming the Kubernetes control plane.

### Tuning for Performance
With tens of thousands of resources reconciling, the team started some performance tuning. Their focus areas:
*   **Reconciliation Intervals:** They increased their platform defaults, tuning intervals to balance responsiveness with load.
*   **Controller Concurrency:** By adjusting the `--concurrent` flags on Flux controllers, they increased how many reconciliations could happen in parallel.
*   **Resource Management:** They monitored and adjusted resource limits for Flux components to ensure reliability under sustained load.

We put a lot of thought into making these knobs available. Flux should run well on a Raspberry Pi and on a fleet of 500 clusters alike. The platform team taking ownership of Flux's runtime in this manner shows operational excellence.

### Moving from Git to S3
The team also moved from a self-hosted Git provider to **S3 buckets** as the source of truth for their clusters. Driven by high availability and compliance requirements, they built a mechanism to push artifacts from CI to S3. Because Flux's `Source Controller` supports various sources - Git, Helm repositories, OCI Repositories, and S3-compatible buckets - this transition was possible. The **GitOps Toolkit** architecture makes this kind of swap straightforward. You change the source layer but keep the delivery pipeline.

## Step 3: Observability and Feedback Loops

Managing 500 clusters requires effective observability. The team built a centralized Grafana dashboard providing a unified view of their fleet.

They extended the open-source Flux dashboards with custom metrics from `kube-state-metrics`, tailored to their developers' needs. At a glance, they could see which reconciliations were failing and why.

They also closed the developer experience loop by integrating Flux's **Notification Controller** - sending success and failure notifications directly to the pipelines and tools developers were already using.

## Looking Ahead

The team also shared what's next on their roadmap:
*   **Flux Sharding:** Exploring sharding Flux controllers to distribute load across multiple instances within a cluster.
*   **OCI Artifacts:** Considering OCI artifacts as the primary source of truth, aligning with the "Git-less GitOps" model for improved performance and security.
*   **Progressive Delivery:** Planning to adopt **Flagger** for canary and blue-green deployments, helping de-risk releases.

It's cool to see a team that's been running Flux for five years still finding new ways to push it further. This is a sophisticated environment, and these improvements could win some performance and improve their developer experience further.

## Watch the Full Talk

For the full story, including the architectural decisions and lessons learned, watch the recording:

{{< youtube 3bLonriwi6g >}}

Thank you to Tiffany, Simon, and the team at Morgan Stanley for sharing their journey so openly. Stories like theirs remind us why we build Flux - what we build for the Raspberry Pi's in our closets at home is the same software that is so widely deployed all around us at enterprise scale. We can't help but wonder what wild stories we'll hear from you all next week at FluxCon and KubeCon!

## Join Us at FluxCon Europe 2026

Inspired by Morgan Stanley's infra? Come connect with the community and learn from teams running Flux in production. **[FluxCon Europe](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/fluxcon/)** is happening on **March 23, 2026** at **RAI Amsterdam**, co-located with KubeCon. Speakers from KLM, NatWest Group, Orange, and more will be sharing their Flux stories.

We'd love to see you there -- come say hi! 🙂
We'll also be in the Project Pavilion all week. Catch up with us at [fluxcd.io/kubecon](https://fluxcd.io/kubecon) 👋