---
title: Running pre and post-deployment jobs with Flux
linkTitle: Running Kubernetes Jobs with Flux
description: "How to run Kubernetes Jobs before and after an application deployment with Flux."
weight: 10
---

Additional considerations have to be made when managing Kubernetes Jobs with Flux.
By default, if you were to have Flux reconcile a Job resource,
it would apply it once to the cluster, the Job would create a Pod that can either error or run to completion.
Attempting to update the Job manifest after it has been applied to the cluster will not be allowed, as changes to the
Job `spec.Completions`, `spec.Selector` and `spec.Template` are not permitted by the Kubernetes API.
To be able to update a Kubernetes Job, the Job has to be recreated by first being
removed and then reapplied to the cluster.

## Repository structure

A typical use case for running Kubernetes Jobs with Flux is to implement pre-deployment tasks
for e.g. database scheme migration and post-deployment jobs (like cache refresh).

This requires separate [Flux Kustomization](/flux/components/kustomize/kustomizations) resources
that depend on each other: one for running the pre-deployment Jobs,
one to deploy the application, and a 3rd one for running the post-deployment Jobs.

Example of an application configuration repository:

```text
├── pre-deploy
│   └── migration.job.yaml
├── deploy
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
├── post-deploy
│   └── cache.job.yaml
└── flux
    ├── pre-deploy.yaml
    ├── deploy.yaml
    └── post-deploy.yaml
```

## Configure the deployment pipeline

Given a Job in the path `./pre-deploy/migration.job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: ghcr.io/org/my-app:v1.0.0
        command:
          - sh
          - -c
          - echo "starting db migration"
```

And a Flux Kustomization that reconciles it at `./flux/pre-deploy.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app-pre-deploy
spec:
  sourceRef:
    kind: GitRepository
    name: my-app
  path: "./pre-deploy/"
  interval: 60m
  timeout: 5m
  prune: true
  wait: true
  force: true
```

Setting `spec.force` to `true` will make Flux recreate the Job when any immutable field is changed,
forcing the Job to run every time the container image tag changes.
Setting `spec.wait` to `true` makes Flux wait for the Job to complete
before it is considered ready.

To deploy the application after the migration job,
we define a Flux Kustomization that depends on the migration one.

Example of `./flux/deploy.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app-deploy
spec:
  dependsOn:
    - name: app-pre-deploy
  sourceRef:
    kind: GitRepository
    name: my-app
  path: "./deploy/"
  interval: 60m
  timeout: 5m
  prune: true
  wait: true
```

This means that the `app-deploy` Kustomization will wait until all the Jobs in `app-pre-deploy` run to completion.
If the Job fails, the app changes will not be applied by the `app-deploy` Kustomization.

And finally we can define a Flux Kustomization that depends on `app-deploy` to run Kubernetes Jobs after the 
application was upgraded.

Example of `./flux/post-deploy.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app-post-deploy
spec:
  dependsOn:
    - name: app-deploy
  sourceRef:
    kind: GitRepository
    name: my-app
  path: "./post-deploy/"
  interval: 60m
  timeout: 5m
  prune: true
  wait: true
  force: true
```

This configuration works best when the Jobs are using the same image and tag as the application being deployed.
When a new version of the application is deployed, the image tags are updated.
The update of the image tag will force a recreation of the Jobs.
The application will be updated after the pre-deployment Jobs have run successfully, and
the post-deployment Jobs will execute only if the app rolling update has completed.
