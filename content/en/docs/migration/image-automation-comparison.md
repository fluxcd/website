---
title: "Changes between v1 and v2 Image Automation"
linkTitle: "Changes between v1 and v2 Image Automation"
description: "Overview of changes between V1 and V2 Image automation"
weight: 20
---

## Changes between v1 and v2

In Flux v1, image update automation is built into the Flux daemon, which scans everything in the cluster and updates the Git repository it is syncing.

In Flux v2,

- image automation is controlled with custom resources, not annotations
- ordering images by build time is not supported (there is [a section
  below](#how-to-migrate-annotations-to-image-policies) explaining what to do instead)
- the fields to update in files are marked explicitly, rather than inferred from annotations.

### Automation is controlled with custom resources

In Flux v2 Image automation is handled by two controllers: The Image Reflector Controller and Image Automation Controller.

The Image Reflector Controller scans image repositories to find the latest images.

The Image Automation Controller uses information from the Image Reflector controller to commit changes to git repositories.

These controllers are separate to the syncing controllers.

In Flux v1 the daemon scans everything and looks at annotations on the resources to determine what to update.

Image automation in v2 is more explicit than in v1 -- you state exactly what images to scan, and what fields to update.

By using custom resources, Flux v2 allows for an arbitrary number of image automations, targeting different Git repositories if you wish, and updating different sets of images.

If you run a multi-tenant cluster, the tenants can define image automations in their own namespaces, for their own Git repositories.

#### Selecting an image is more flexible

In Flux v1, you supply a filter pattern, and the latest image is the image with the most recent build time out of those filtered.

In Flux v2, you choose an ordering, and separately specify a filter for the tags to consider.

These are dealt with in detail below.

Selecting an image by build time is not supported in Flux v2.

This is the implicit default in Flux v1.

In Flux v2, you will need to tag images so that they sort in the order you would like -- [see below](#using-sortable-image-tags) for how to do this conveniently.

#### Fields to update are explicitly marked

In Flux v1 the fields to update are inferred from the type of the resource, along with the annotations given.

In Flux v2 the fields to update in files are marked explicitly.

Flux v1 is limited to the types that are programmed in.

Flux v2 can update any Kubernetes object (and some files that aren't Kubernetes objects, like `kustomization.yaml`).

## Preparing for migration

Complete migration of your system to _Flux v2 syncing_, using the [Flux v1 migration guide][flux-v1-migration].

This will remove Flux v1 from the system, along with its image
automation.

Reintroduce automation with Flux v2 by following the instructions in this guide.

It is safe to leave the annotations for Flux v1 in files while you reintroduce automation, as Flux v2 will ignore them.
