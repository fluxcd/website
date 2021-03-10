---
title: Sources
description: Sources are used to declare where resources are to be obtained from
weight: 3
---

## What is a Source?

A *Source* defines the origin of an external resource and the requirements to obtain
it (e.g. credentials, version selectors). For example, the latest `1.x` tag
available from a Git repository over SSH.

Sources produce an artifact that is consumed by other Flux elements to perform
actions, like applying the contents of the artifact on the cluster. A source
may be shared by multiple consumers to deduplicate configuration and/or storage.

## Working with Sources

In flux there are 3 types of sources
- GitRepository 
- HelmRepository
- Bucket

These sources are defined as Custom Resources in Kubernetes.
You can create a source by hand, or by using the Flux command line tool, see the following examples

### GitRepository
```bash
$ flux 
```
```yaml
asdas  

```
### HelmRepository
```bash
$ flux 
```
```yaml
asdas  

```
### Bucket
```bash
$ flux 
```
```yaml
asdas  

```
## Sources in action

When you add a source to your cluster the following will happen
- Added to k8s
- source controller will

The origin of the source is checked for changes on a defined interval, if
there is a newer version available that matches the criteria, a new artifact
is produced.


For more information, take a look at [the source controller documentation](../components/source/source.md).