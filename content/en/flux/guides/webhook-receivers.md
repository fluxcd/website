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

The notification controller handles webhook requests on port `9292`
and comes with a Kubernetes Service named `webhook-receiver` that
maps the port to `80` inside the cluster.

The webhook receiver port can be used to create a Kubernetes LoadBalancer Service,
Ingress or HTTPRoute (Gateway API).

## Using a LoadBalancer

Create a `Service` of type `LoadBalancer` in the `flux-system` namespace
pointing to the `notification-controller` pods on port `9292`:

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

## Using an Ingress

Create an `Ingress` in the `flux-system` namespace pointing to the Kubernetes
service named `webhook-receiver`on port `80`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webhook-receiver
  namespace: flux-system
spec:
  rules:
  - host: webhook-receiver.example.com
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

Add any necessary annotations for your ingress controller and cert-manager
to provide for encryption. Full configuration of cert-manager issuers,
ingress controllers, and TLS are beyond the scope of this documentation.

However, one common issue caused by Flux's default network policy securing
the `flux-system` namespace is that unexpected traffic to any pod in that namespace is prevented.
The HTTP-01 ACME challenge ingress is blocked from receiving cert-manager traffic.

An example of a policy that permits the traffic from only namespaces with a
matching `cert-manager` label into the challenge pod follows:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-cert-manager-resolver
  namespace: "flux-system"
spec:
  podSelector:
    matchLabels:
      acme.cert-manager.io/http01-solver: "true"
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              app.kubernetes.io/instance: cert-manager
```

Your environment's network policy details may vary. Please take care that the policy
is appropriate for the security posture of your environment.

## Using a HTTPRoute (Gateway API)

Create a `HTTPRoute` in the `flux-system` namespace pointing to the Kubernetes
service named `webhook-receiver` on port `80`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: webhook-receiver
  namespace: flux-system
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: internet-gateway
      namespace: gateway-namespace
  hostnames:
    - "webhook-receiver.example.com"
  rules:
    - matches:
      - path:
          type: PathPrefix
          value: /
      backendRefs:
        - name: webhook-receiver
          namespace: flux-system
          port: 80
```

Note the `parentRefs` section must be updated to match your Gateway configuration.

If the Gateway proxy is running in the cluster, the Flux network policy
[allow-webhooks](https://github.com/fluxcd/flux2/blob/main/manifests/policies/allow-webhooks.yaml)
will allow the traffic to the `notification-controller` pods without any further configuration.

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

Webhooks can also be used to trigger `ImageRepository` and `OCIRepository`
resources to reconcile immediately when the GitHub repositories publish new
images to them.

The `Receiver` is configured as follows: the `package` event replaces `push`,
and for the webhook configuration select the GitHub webhook "Package" event in
the list marked "Let me select individual events."

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: webapp-image
  namespace: flux-system
spec:
  type: github
  events:
    - "ping"
    - "package"
  secretRef:
    name: webhook-token
  resources:
    - kind: ImageRepository
      name: webapp
```

Receivers should reconcile source kinds, not the appliers downstream of them.
When any Flux image or source kind detects a new artifact revision, Flux will
automatically notify `Kustomization`, `HelmRelease`, or `ImageUpdateAutomation`
resources downstream of those without any further configuration.

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
