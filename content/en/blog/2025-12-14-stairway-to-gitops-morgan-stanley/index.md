---
author: Flux Team
date: 2025-01-26 12:00:00+00:00
title: "Stairway to GitOps: Scaling Flux at Morgan Stanley"
description: "Reflecting on Morgan Stanley's journey to production GitOps with Flux, presented at FluxCon NA 2025."
url: /blog/2025/12/stairway-to-gitops-morgan-stanley/
tags: [fluxcon, user-story, enterprise, scale]
---

Seeing how the community applies Flux to solve complex, real-world problems is a highlight for us as maintainers. At our inaugural FluxCon NA, **Tiffany Wang** and **Simon Bourassa** from **Morgan Stanley** shared their five-year journey of adopting and scaling Flux.

Their talk, titled **"Stairway to GitOps,"** detailed their evolution from push-based pipelines to a robust, self-service GitOps platform managing over 500 clusters. For us, seeing the principles of Flux-**Lean, Performant, Extensible, and Secure**—validated at this scale excites us and brings us confidence.

We wanted to highlight the key learnings from their presentation that resonated with the Flux community.

## The Early Days: Pushing Limits

Morgan Stanley began with traditional push-based CI/CD pipelines, where application teams used tools like Helm to push manifests directly to clusters. While functional for initial deployments, challenges emerged as they scaled.

The team described specific pain points:
*   **Configuration Drift:** Without an agent continuously reconciling state, the cluster drifted from the source of truth in Git. Manual changes or failed deployments left the system in an unknown state.
*   **Fragile Recovery:** Disruptive operations, such as cluster rebuilds, required significant coordination. The platform team could restore the infrastructure, but application teams had to manually redeploy their workloads.

At "Step 0" of their Stairway to GitOps, they realize they need to decouple delivery from the pipeline and ensure continuous reconciliation.

## Step 1: Security and Self-Service

In a highly regulated financial environment, security is a hard requirement. The team needed to ensure that adopting Flux maintained their strict multi-tenancy models.

Morgan Stanley leveraged **Flux's service account impersonation** and native Kubernetes RBAC to enforce a least-privilege model. They configured Flux so that a controller reconciling manifests for one team had no permissions to access resources belonging to another. This ability to scope permissions granularly while using  shared controllers is central to how Flux enables secure multi-tenancy.

To streamline adoption, they built a **self-service onboarding platform**. Instead of requiring developers to manage low-level Kubernetes details, they created tooling that:
1.  Automated entitlement checks and change control processes.
2.  Registered services in their CMDB.
3.  "Primed" the target namespace with the necessary Flux `GitRepository` and `Kustomization` resources.
4.  Scaffolded a ready-to-use application repository.

This approach demonstrates Flux's extensibility, serving as the engine under the hood while developers interact with higher-level abstractions.

## Step 2: Operating at Scale

As adoption grew, the scale became significant. Tiffany Wang shared the current numbers:

> *"And now we have over 500 clusters, over 2,000 nodes, over 100,000 containers, and tens of thousands of Flux resources."* (13:34)

Operating at this magnitude brings challenges around performance. The team shared how they tuned Flux to handle this load without overwhelming the Kubernetes control plane.

### Tuning for Performance
With tens of thousands of resources reconciling, default settings were adjusted. The team engaged in performance tuning, focusing on:
*   **Reconciliation Intervals:** They increased their platform defaults, tuning intervals to balance responsiveness with load.
*   **Controller Concurrency:** By adjusting the `--concurrent` flags on the Flux controllers, they increased how many reconciliations could happen in parallel.
*   **Resource Management:** They monitored and adjusted the resource limits for the Flux components to ensure reliability under load.

This level of tunability is a design goal for Flux, allowing it to run efficiently in diverse environments, from home labs to large financial institutions.

### Moving from Git to S3
The team also moved from a self-hosted Git provider to **S3 buckets** as the source of truth for their clusters. Driven by requirements for high availability and compliance, they built a mechanism to push artifacts from their CI system to S3. Because Flux's `Source Controller` supports various sources—including Git, Helm repositories, OCI Repositories, and S3-compatible buckets—this transition was possible. This demonstrates the flexibility of the **GitOps Toolkit** architecture: swapping out the source layer without rewriting the delivery pipeline.

## Step 3: Observability and Feedback Loops

Managing 500 clusters requires effective observability. The team built a centralized Grafana dashboard providing a unified view of their fleet.

They augmented the open-source Flux dashboards with custom metrics from `kube-state-metrics` to provide a view tailored to their developers. This allowed them to see which reconciliation was failing and why.

They also closed the loop on the developer experience by integrating Flux's **Notification Controller**. Instead of forcing developers to check a dashboard, they sent success and failure notifications directly back to the pipelines and tools developers were already using.

## Looking Ahead

The journey continues, with the team sharing their roadmap for the future:
*   **Flux Sharding:** To push scale further, they are exploring sharding Flux controllers to distribute the load across multiple instances within a cluster.
*   **OCI Artifacts:** They are considering a move to OCI artifacts as their primary source of truth, aligning with the "Git-less GitOps" model for improved performance and security characteristics.
*   **Progressive Delivery:** They plan to adopt **Flagger** to enable canary and blue-green deployments, helping to de-risk releases.

## Watch the Full Talk

For more detail on the architectural decisions and lessons learned, you can watch the full recording:

{{< youtube qPHhdbqU6vQ >}}

We are grateful to Tiffany, Simon, and the team at Morgan Stanley for their contributions to the community. Their story shows what is possible with Flux, and encourages us to keep building tools that are ready for enterprise scale.
