---
title: "Setup Webhook Receivers"
linkTitle: "Setup Webhook Receivers"
description: "Configure webhook receivers for GitHub, GitLab, DockerHub and others using Flux notification controller."
weight: 40
---

Flux is by design **pull-based**.
In order to notify the Flux controllers about changes in Git or Helm repositories,
you can setup webhooks and trigger a cluster reconciliation
every time a source changes. Using webhook receivers make
**pull-based** pipelines as responsive as **push-based** pipelines.

## Prerequisites

To follow this guide you'll need a Kubernetes cluster with the GitOps 
toolkit controllers installed on it.
Please see the [get started guide](/flux/get-started/)
or the [installation guide](/flux/installation/).

The [notification controller](/flux/components/notification/)
can handle events coming from external systems
(GitHub, GitLab, Bitbucket, Harbor, Jenkins, etc)
and notify the GitOps toolkit controllers about source changes.
The notification controller is part of the default toolkit installation.

## Expose the webhook receiver

In order to receive Git push or Helm chart upload events, you'll have to 
expose the webhook receiver endpoint outside of your Kubernetes cluster on 
a public address.

The notification controller handles webhook requests on port `9292`.
This port can be used to create a Kubernetes LoadBalancer Service or Ingress.

Create a `LoadBalancer` service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: receiver
  namespace: flux-system
spec:
  type: LoadBalancer
  selector:
    app: notification-controller
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 9292
```

Wait for Kubernetes to assign a public address with:

```sh
watch kubectl -n flux-system get svc/receiver
``` 

...or, create an `Ingress` with the same destination, the `notification-webhook` http service on port 80:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webhook-receiver
  namespace: flux-system
spec:
  rules:
  - host: flux-webhook.example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: webhook-receiver
            port:
              number: 80
```

Add any necessary annotations for your ingress controller or, for example, cert-manager to encrypt the endpoint with TLS; full configuration of ingress controllers and TLS are beyond the scope of this documentation.

## Define a Git repository

Create a Git source pointing to a GitHub repository that you have control over:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: webapp
  namespace: flux-system
spec:
  interval: 60m
  url: https://github.com/<GH-ORG>/<GH-REPO>
  ref:
    branch: master
```

{{% alert color="info" title="Authentication" %}}
SSH or token based authentication can be configured for private repositories.
See the [GitRepository CRD docs](/flux/components/source/gitrepositories/) for more details.
{{% /alert %}}

## Define a Git repository receiver

First generate a random string and create a secret with a `token` field:

```sh
TOKEN=$(head -c 12 /dev/urandom | shasum | cut -d ' ' -f1)
echo $TOKEN

kubectl -n flux-system create secret generic webhook-token \	
--from-literal=token=$TOKEN
```

Create a receiver for GitHub and specify the `GitRepository` object:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: webapp
  namespace: flux-system
spec:
  type: github
  events:
    - "ping"
    - "push"
  secretRef:
    name: webhook-token
  resources:
    - kind: GitRepository
      name: webapp
```

{{% alert color="info" title="Other receiver" %}}
Besides GitHub, you can define receivers for **GitLab**, **Bitbucket**, **Harbor**
and any other system that supports webhooks e.g. Jenkins, CircleCI, etc.
See the [Receiver CRD docs](/flux/components/notification/receiver/) for more details.
{{% /alert %}}

The notification controller generates a unique URL using the provided token and the receiver name/namespace.

Find the URL with:

```sh
$ kubectl -n flux-system get receiver/webapp

NAME     READY   STATUS
webapp   True    Receiver initialised with URL: /hook/bed6d00b5555b1603e1f59b94d7fdbca58089cb5663633fb83f2815dc626d92b
```

On GitHub, navigate to your repository and click on the "Add webhook" button under "Settings/Webhooks". 
Fill the form with:

* **Payload URL**: compose the address using the receiver LB and the generated URL `http://<LoadBalancerAddress>/<ReceiverURL>`
* **Secret**: use the `token` string

With the above settings, when you push a commit to the repository, the following happens:

* GitHub sends the Git push event to the receiver address
* Notification controller validates the authenticity of the payload using HMAC
* Source controller is notified about the changes
* Source controller pulls the changes into the cluster and updates the `GitRepository` revision
* Kustomize controller is notified about the revision change
* Kustomize controller reconciles all the `Kustomizations` that reference the `GitRepository` object
