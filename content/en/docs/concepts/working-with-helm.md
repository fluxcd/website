---
title: Working With Helm
description: How does Flux2 work with Helm?
weight: 6
---

Flux provides support for deploying helm Charts.

## What does deploying a helm chart with Flux entail?

- Declare where your helmchart is stored using the appropriate [source]
    - HelmRepository
    - GitRepository
    - Bucket
- Define a Helm release object
  - Either using the command line or by hand
- 
- Commit both these to git
- Flux will reconcile

## Common Patterns for managing values

Ready to try things yourself?
try out our [helm guide] whoop whoop


[source]: ../sources
[helm guide]: ../../guides/helmreleases