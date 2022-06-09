---
title: Running Jobs With Flux
linkTitle: Running Jobs
description: "How to run Jobs with Flux."
weight: 10
---

Additional considerations have to be made when managing Kubernetes Jobs with Flux. By default if you were to have Flux manage a single Job resource, it would apply it once to the cluster. The Job would trigger a run which would create a Pod that can either error or run to completion. Attempting to update the Job after it has been applied to the cluster will not be allowed as changed to the Jobs `spec.Completions`, `spec.Selector` or `spec.Template` is not permitted by the Kubernetes API. To be able to update a Job the Job has to be recreated by first beeing removed and the reapplied to the cluster.

A typical use case for running Jobs with Flux is to implement post deployment tasks such as database scheme migration. This requires two seperate Kustomization resources to implement. One to create or recreate the Job and another to deploy the application.

Given a simple Job in the path `./pre/job.yaml`.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pre
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pre
        image: alpine
        command:
          - sh
          - -c
          - |
            echo "starting"
            sleep 10
            echo "complete"
```

The following Kustomization will deploy the Job. Setting `` to true will make Flux recreate the Job when any immutable field is changed. Forcing the Job to run once again. Setting `` to true will make the Kustomization resource wait for the Job to complete before it is considered ready.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: pre
spec:
  interval: 1m
  path: ./pre/
  prune: true
  wait: true
  force: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
```

With this configuration another Kustomization can depend on the `pre` Kustomization. This means that the depending Kustomization will wait until the Job completes. If the Job fails the changes will not be applied to the depending Kustomization.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: application
spec:
  interval: 1m
  path: ./application/
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  dependsOn:
    - name: pre
```

This configuration works best when the Job uses the same image and tag as the application beeing deployed. When a new version of the application is deployed both iamge tags are updated. The updating of the image tag will force a recreation of the Job. The application will in this case not be deployed before the Job has finished running.
