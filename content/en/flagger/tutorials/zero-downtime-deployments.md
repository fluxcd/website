---
weight: 15
title: Zero downtime deployments
---

This is a list of things you should consider when dealing with a high traffic production environment if you want to minimise the impact of rolling updates and downscaling.

## Deployment strategy

Limit the number of unavailable pods during a rolling update:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  progressDeadlineSeconds: 120
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
```

The default progress deadline for a deployment is ten minutes. You should consider adjusting this value to make the deployment process fail faster.

## Liveness health check

You application should expose a HTTP endpoint that Kubernetes can call to determine if your app transitioned to a broken state from which it can't recover and needs to be restarted.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  timeoutSeconds: 5
  initialDelaySeconds: 5
```

## Readiness health check

You application should expose a HTTP endpoint that Kubernetes can call to determine if your app is ready to receive traffic.

```yaml
readinessProbe:
  httpGet:
    path: /readyz
    port: 8080
  timeoutSeconds: 5
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Hold application until Service Mesh Sidecar starts

If your app depends on external services, you should check if those services are available before allowing Kubernetes to route traffic to an app instance. Keep in mind that the service mesh sidecar proxy can have a slower startup than your app. This means that on application start you should retry for at least a couple of seconds any external connection.

How to avoid this on various service mesh:
- Istio: [holdApplicationUntilProxyStarts=true](https://istio.io/latest/docs/ops/common-problems/injection/#pod-or-containers-start-with-network-issues-if-istio-proxy-is-not-ready)
- Linkerd: [config.linkerd.io/proxy-await=enabled](https://linkerd.io/2.13/reference/proxy-configuration/)

## Graceful shutdown

Before a pod gets terminated, Kubernetes sends a `SIGTERM` signal to every container and waits for period of time \(30s by default\) for all containers to exit gracefully. If your app doesn't handle the `SIGTERM` signal or if it doesn't exit within the grace period, Kubernetes will kill the container and any inflight requests that your app is processing will fail.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: app
        lifecycle:
          preStop:
            exec:
              command:
              - sleep
              - "15"
```

In the example above, `terminationGracePeriodSeconds` is 60, and the preStop hook takes 15 seconds to complete, and the Container will have 45 seconds to stop normally

This will allow the Kubernetes to drain the traffic and remove this pod from all other [Endpoints](https://kubernetes.io/docs/concepts/services-networking/service/#endpoints) and Envoy sidecars before your app becomes unavailable.

## Delay Service mesh proxy shutdown

Even if your app reacts to `SIGTERM` and tries to complete the inflight requests before shutdown, that doesn't mean that the response will make it back to the caller. If the service mesh sidecar shuts down before your app, then the caller will receive a 503 error.

- Istio: configure via the parameter [terminationDrainDuration](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/) in the Istio `ProxyConfig` and wait for the existing connections to complete in the app
- Linkerd: [config.linkerd.io/shutdown-grace-period](https://linkerd.io/2.13/tasks/graceful-shutdown/#configuration-options-for-graceful-shutdown)

## Resource requests and limits

Setting CPU and memory requests/limits for all workloads is a mandatory step if you're running a production system. Without limits your nodes could run out of memory or become unresponsive due to CPU exhausting. Without CPU and memory requests, the Kubernetes scheduler will not be able to make decisions about which nodes to place pods on.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          limits:
            cpu: 1000m
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 128Mi
```

Note that without resource requests the horizontal pod autoscaler can't determine when to scale your app.

## Autoscaling

A production environment should be able to handle traffic bursts without impacting the quality of service. This can be achieved with Kubernetes autoscaling capabilities. Autoscaling in Kubernetes has two dimensions: the Cluster Autoscaler that deals with node scaling operations and the Horizontal Pod Autoscaler that automatically scales the number of pods in a deployment.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 3
  maxReplicas: 12
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

The above HPA ensures your app will be scaled up before the pods reach the CPU or memory limits.

## Ingress retries

To minimise the impact of downscaling operations you can make use of Envoy retry capabilities.

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
spec:
  service:
    port: 9898
    gateways:
    - public-gateway.istio-system.svc.cluster.local
    hosts:
    - app.example.com
    retries:
      attempts: 10
      perTryTimeout: 5s
      retryOn: "gateway-error,connect-failure,refused-stream"
```

When the HPA scales down your app, your users could run into 503 errors. The above configuration will make Envoy retry the HTTP requests that failed due to gateway errors.
