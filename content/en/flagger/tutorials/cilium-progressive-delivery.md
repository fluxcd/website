---
weight: 1
title: Cilium Gateway API Canary Deployments
---

This guide shows you how to use Cilium's implementation of the [Gateway API](https://gateway-api.sigs.k8s.io/) and Flagger to automate canary deployments and A/B testing.

![Flagger Canary Stages](/img/diagrams/flagger-canary-steps.png)

## Prerequisites

Flagger requires a Kubernetes cluster **v1.19** or newer and any mesh/ingress that implements the `v1beta1` version of Gateway API.

Ensure that you have the Kubernetes Gateway API CRDs installed:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```

Install Cilium with Gateway API enabled:
```bash
# To install with Helm
helm install cilium cilium/cilium \
    --namespace kube-system \
    --set gatewayAPI.enabled=true \ 
    --set kubeProxyReplacement=true 
```
This will also create a `GatewayClass` on your behalf. Try running `kubectl get gatewayclass -A` to verify it is there.

Install Flagger in the `flagger-system` namespace:

```bash
kubectl apply -k github.com/fluxcd/flagger//kustomize/gatewayapi
```
## Creating the Gateway
Create a `cilium` namespace:
```bash
kubectl create ns cilium
```
Create a `Gateway` that configures load balancing, traffic ACL, etc:
```yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: cilium
  namespace: cilium
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

----
## Bootstrap

Flagger takes a Kubernetes deployment and optionally a horizontal pod autoscaler \(HPA\), then creates a series of objects \(Kubernetes deployments, ClusterIP services, HTTPRoutes for the Gateway\). These objects expose the application inside the mesh and drive the canary analysis and promotion.

Create a test namespace:

```bash
kubectl create ns test
```

Create a deployment and a horizontal pod autoscaler:

```bash
kubectl apply -k https://github.com/fluxcd/flagger//kustomize/podinfo?ref=main
```

Deploy the load testing service to generate traffic during the canary analysis:

```bash
kubectl apply -k https://github.com/fluxcd/flagger//kustomize/tester?ref=main
```

Create metric templates targeting the Prometheus server in the `flagger-system` namespace. This example will use the default metrics that Flagger provides. You can [change it to your ingress/mesh provider](/flagger/faq#metrics) accordingly.

```yaml
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: latency
  namespace: flagger-system
spec:
  provider:
    type: prometheus
    address: http://flagger-prometheus:9090
  query: |
    histogram_quantile(0.99,
      sum(
        rate(
          envoy_cluster_upstream_rq_time_bucket{
            envoy_cluster_name=~"{{ namespace }}_{{ target }}-canary_[0-9a-zA-Z-]+",
          }[{{ interval }}]
        )
      ) by (le)
    )/1000
---
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: error-rate
  namespace: flagger-system
spec:
  provider:
    type: prometheus
    address: http://flagger-prometheus:9090
  query: |
    100 - sum(
      rate(
        http_requests_total{
          namespace="{{ namespace }}",
          status!~"5.*"
        }[{{ interval }}]
      )
    )
    /
    sum(
      rate(
        http_requests_total{
          namespace="{{ namespace }}",
        }[{{ interval }}]
      )
    )
    * 100
```

Save the above resource as metric-templates.yaml and then apply it:

```bash
kubectl apply -f metric-templates.yaml
```

Create a canary custom resource \(replace "loaclproject.contour.io" with your own domain\):
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: test
spec:
  # deployment reference
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  # the maximum time in seconds for the canary deployment
  # to make progress before it is rollback (default 600s)
  progressDeadlineSeconds: 60
  # HPA reference (optional)
  autoscalerRef:
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    name: podinfo
  service:
    # service port number
    port: 9898
    # container port number or name (optional)
    targetPort: 9898
    # Gateway API HTTPRoute host names
    # Reference to the Gateway that the generated HTTPRoute would attach to.
    gatewayRefs:
      - name: cilium
        namespace: cilium
  analysis:
    # schedule interval (default 60s)
    interval: 1m
    # max number of failed metric checks before rollback
    threshold: 5
    # max traffic percentage routed to canary
    # percentage (0-100)
    maxWeight: 50
    # canary increment step
    # percentage (0-100)
    stepWeight: 10
    metrics:
    - name: request-success-rate
      interval: 1m
      # minimum req success rate (non 5xx responses)
      # percentage (0-100)
      thresholdRange:
        min: 99
    - name: error-rate
      # max error rate (5xx responses)
      # percentage (0-100)
      templateRef:
        name: error-rate
        namespace: flagger-system
      thresholdRange:
        max: 1
      interval: 1m
    - name: latency
      templateRef:
        name: latency
        namespace: flagger-system
      # seconds
      thresholdRange:
         max: 0.5
      interval: 30s
```

```bash
# applied 
deployment.apps/podinfo
horizontalpodautoscaler.autoscaling/podinfo
canary.flagger.app/podinfo

# generated 
deployment.apps/podinfo-primary
horizontalpodautoscaler.autoscaling/podinfo-primary
service/podinfo
service/podinfo-canary
service/podinfo-primary
httproutes.gateway.networking.k8s.io/podinfo
```

## Automated canary promotion

Trigger a canary deployment by updating the container image:

```bash
kubectl -n test set image deployment/podinfo \
podinfod=ghcr.io/stefanprodan/podinfo:6.0.1
```

Flagger detects that the deployment revision changed and starts a new rollout:

```text
kubectl -n test describe canary/podinfo

Status:
  Canary Weight:         0
  Failed Checks:         0
  Phase:                 Succeeded
Events:
  Type     Reason  Age   From     Message
  ----     ------  ----  ----     -------
  Normal   Synced  3m    flagger  New revision detected podinfo.test
  Normal   Synced  3m    flagger  Scaling up podinfo.test
  Warning  Synced  3m    flagger  Waiting for podinfo.test rollout to finish: 0 of 1 updated replicas are available
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 5
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 10
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 15
  Normal   Synced  2m    flagger  Advance podinfo.test canary weight 20
  Normal   Synced  2m    flagger  Advance podinfo.test canary weight 25
  Normal   Synced  1m    flagger  Advance podinfo.test canary weight 30
  Normal   Synced  1m    flagger  Advance podinfo.test canary weight 35
  Normal   Synced  55s   flagger  Advance podinfo.test canary weight 40
  Normal   Synced  45s   flagger  Advance podinfo.test canary weight 45
  Normal   Synced  35s   flagger  Advance podinfo.test canary weight 50
  Normal   Synced  25s   flagger  Copying podinfo.test template spec to podinfo-primary.test
  Warning  Synced  15s   flagger  Waiting for podinfo-primary.test rollout to finish: 1 of 2 updated replicas are available
  Normal   Synced  5s    flagger  Promotion completed! Scaling down podinfo.test
```

**Note** that if you apply new changes to the deployment during the canary analysis, Flagger will restart the analysis.

A canary deployment is triggered by changes in any of the following objects:

* Deployment PodSpec \(container image, command, ports, env, resources, etc\)
* ConfigMaps mounted as volumes or mapped to environment variables
* Secrets mounted as volumes or mapped to environment variables

You can monitor how Flagger progressively changes the weights of the HTTPRoute object that is attahed to the Gateway with:

```bash
watch kubectl get httproute -n test podinfo -o=jsonpath='{.spec.rules}'
```

You can monitor all canaries with:

```bash
watch kubectl get canaries --all-namespaces

NAMESPACE   NAME      STATUS        WEIGHT   LASTTRANSITIONTIME
test        podinfo   Progressing   15       2022-01-16T14:05:07Z
prod        frontend  Succeeded     0        2022-01-15T16:15:07Z
prod        backend   Failed        0        2022-01-14T17:05:07Z
```


## Automated rollback

During the canary analysis you can generate HTTP 500 errors and high latency to test if Flagger pauses the rollout.

Trigger another canary deployment:

```bash
kubectl -n test set image deployment/podinfo \
podinfod=ghcr.io/stefanprodan/podinfo:6.0.2
```

Exec into the load tester pod with:

```bash
kubectl -n test exec -it flagger-loadtester-xx-xx sh
```

Generate HTTP 500 errors:

```bash
watch curl http://podinfo-canary:9898/status/500
```

Generate latency:

```bash
watch curl http://podinfo-canary:9898/delay/1
```

When the number of failed checks reaches the canary analysis threshold, the traffic is routed back to the primary, the canary is scaled to zero and the rollout is marked as failed.

```text
kubectl -n test describe canary/podinfo

Status:
  Canary Weight:         0
  Failed Checks:         10
  Phase:                 Failed
Events:
  Type     Reason  Age   From     Message
  ----     ------  ----  ----     -------
  Normal   Synced  3m    flagger  Starting canary deployment for podinfo.test
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 5
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 10
  Normal   Synced  3m    flagger  Advance podinfo.test canary weight 15
  Normal   Synced  3m    flagger  Halt podinfo.test advancement success rate 69.17% < 99%
  Normal   Synced  2m    flagger  Halt podinfo.test advancement success rate 61.39% < 99%
  Normal   Synced  2m    flagger  Halt podinfo.test advancement success rate 55.06% < 99%
  Normal   Synced  2m    flagger  Halt podinfo.test advancement success rate 47.00% < 99%
  Normal   Synced  2m    flagger  (combined from similar events): Halt podinfo.test advancement success rate 38.08% < 99%
  Warning  Synced  1m    flagger  Rolling back podinfo.test failed checks threshold reached 10
  Warning  Synced  1m    flagger  Canary failed! Scaling down podinfo.test
```

The above procedures can be extended with [custom metrics](../usage/metrics.md) checks, [webhooks](../usage/webhooks.md), [manual promotion](../usage/webhooks.md#manual-gating) approval and [Slack or MS Teams](../usage/alerting.md) notifications.
