---
title: "Security Best Practices"
linkTitle: "Best Practices"
description: "Best practices for securing Flux deployments."
weight: 140
---

## Introduction

The Flux project strives to keep its components secure by design and by default.
This document aims to list all security-sensitive options or considerations that
must be taken into account when deploying Flux. And also serve as a guide for
security professionals auditing such deployments.

Not all recommendations are required for a secure deployment. Some may impact the
convenience, performance or resources utilization of Flux. Therefore, use this in
combination with your own Security Posture and Risk Appetite.

Some recommendations may overlap with Kubernetes security recommendations, to keep
this short and more easily maintainable, please refer to
[Kubernetes CIS Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
for non Flux-specific guidance.

For help implementing these recommendations, seek [enterprise support](/support/#commercial-support).

## Security Best Practices

The recommendations below are based on Flux's latest version.

### Helm Controller

#### Start-up flags

- Ensure controller was not started with `--insecure-kubeconfig-exec=true`.
  <details>
    <summary>Rationale</summary>

    KubeConfigs support the execution of a binary command to return the token required to authenticate against a Kubernetes cluster.

    This is very handy for acquiring contextual tokens that are time-bound (e.g. aws-iam-authenticator).  
    However, this may be open for abuse in multi-tenancy environments and therefore is disabled by default.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check Helm Controller's pod YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure controller was not started with `--insecure-kubeconfig-tls=true`.
  <details>
    <summary>Rationale</summary>

    Disables the enforcement of TLS when accessing the API Server of remote clusters.
    
    This flag was created to enable scenarios in which non-production clusters need to be accessed via HTTP. Do not disable TLS in production.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check Helm Controller's pod YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    ```
  </details>

### Kustomize Controller

#### Start-up flags

- Ensure controller was not started with `--insecure-kubeconfig-exec=true`.
  <details>
    <summary>Rationale</summary>

    KubeConfigs support the execution of a binary command to return the token required to authenticate against a Kubernetes cluster.

    This is very handy for acquiring contextual tokens that are time-bound (e.g. aws-iam-authenticator).

    However, this may be open for abuse in multi-tenancy environments and therefore is disabled by default.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check Kustomize Controller's pod YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure controller was not started with `--insecure-kubeconfig-tls=true`.
  <details>
    <summary>Rationale</summary>

    Disables the enforcement of TLS when accessing the API Server of remote clusters.
    
    This flag was created to enable scenarios in which non-production clusters need to be accessed via HTTP. Do not disable TLS in production.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check Kustomize Controller's pod YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure controller was started with `--no-remote-bases=true`.
  <details>
    <summary>Rationale</summary>

    By default the Kustomize controller allows for kustomize overlays to refer to external bases. 
    This has a performance penalty, as the bases will have to be downloaded on demand during each reconciliation.<br>
    When using external bases, there can't be any assurances that the externally declared state won't change.
    In this case, the source loses its hermetic properties. Changes in the external bases will result in changes on the cluster, regardless of whether the source has been modified since the last reconciliation.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check Kustomize Controller's pod YAML for the arguments used at start-up:

    ```sh
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    ```
  </details>

#### Secret Decryption

- Ensure Secret Decryption is enabled and secrets are not being held in Flux Sources in plaintext.
  <details>
    <summary>Rationale</summary>

    The kustomize-controller has an auto decryption mechanism that can decrypt cipher texts on-demand at reconciliation time using an embedded implementation of [SOPS](https://github.com/mozilla/sops). This enables credentials (e.g. passwords, tokens) and sensitive information to be kept in an encrypted state in the sources.    
  </details>
  <details>
    <summary>Audit Procedure</summary>
    
    - Check for plaintext credentials stored in the Git Repository at both HEAD and historical commits. Auto-detection tools can be used for this such as [GitLeaks](https://github.com/zricethezav/gitleaks), [Trufflehog](https://github.com/trufflesecurity/trufflehog) and [Squealer](https://github.com/owenrumney/squealer).
    - Check whether Secret Decryption is properly enabled in each `spec.decryption` field of the cluster's `Kustomization` objects.
  </details>

## Additional Best Practices for Shared Cluster Multi-tenancy

### Multi-tenancy Lock-down

- Ensure `helm-controller`, `kustomize-controller`, `notification-controller`, `image-reflector-controller` and `image-automation-controller` have cross namespace references disabled via `--no-cross-namespace-refs=true`.

  <details>
    <summary>Rationale</summary>

    Blocks references to Flux objects across namespaces. This assumes that tenants would own one or multiple namespaces, and should not be allowed to consume other tenant's objects, as this could enable them to gain access to sources they do not (or should not) have access to.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check the Controller's YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=notification-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=image-reflector-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=image-automation-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure `helm-controller` and `kustomize-controller` have a default service account set via `--default-service-account=<service-account-name>`.

  <details>
    <summary>Rationale</summary>

    Enforces all reconciliations to impersonate a given Service Account, effectively disabling the use of the privileged service account that would otherwise be used by the controller.

    Tenants must set a service account for each object that is responsible for applying changes to the Cluster (i.e. [HelmRelease](/flux/components/helm/helmreleases/#enforcing-impersonation) and [Kustomization](/flux/components/kustomize/kustomizations/#enforcing-impersonation)), otherwise Kubernetes's API Server will not authorize the changes. NB: It is recommended that the default service account used has no permissions set to the control plane.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check the Controller's YAML for the arguments used at start-up:
    
    ```sh
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure all Flux controllers have default service accounts set for workload identity authentication via the `--default-service-account=<service-account-name>`, `--default-decryption-service-account=<service-account-name>` and `--default-kubeconfig-service-account=<service-account-name>` flags.

  <details>
    <summary>Rationale</summary>

    In multi-tenant environments, workload identity authentication should be locked down to force tenant permissions used in cloud provider integrations to be provisioned following the Principle of Least Privilege. This ensures proper isolation between tenants with regards to ownership of cloud resources. This is separate from the Kubernetes RBAC impersonation controls mentioned above.

    Setting default service accounts ensures that when Flux resources don't specify a service account for workload identity authentication, they fall back to a controlled default expected to exist in the resource's namespace, i.e. in the tenant's namespace.

    The workload identity default service account flags are `--default-decryption-service-account` and `--default-kubeconfig-service-account` for `kustomize-controller`, `--default-kubeconfig-service-account` for `helm-controller`, and `--default-service-account` for `source-controller`, `notification-controller`, `image-reflector-controller` and `image-automation-controller`.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check all Flux controllers for workload identity default service account flags (`--default-service-account`, `--default-decryption-service-account`, `--default-kubeconfig-service-account`):
    
    ```sh
    kubectl describe pod -n flux-system -l app=source-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=notification-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=image-reflector-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=image-automation-controller | grep -B 5 -A 10 Args
    ```
  </details>

### Secret Decryption

- Ensure Secret Decryption is configured correctly, such that each tenant have the correct level of isolation.
  <details>
    <summary>Rationale</summary>

    The secret decryption configuration must be aligned with the level of isolation required across tenants.
    - For higher isolation, each tenant must have their own Key Encryption Key (KEK) configured. Note that the access controls to the aforementioned keys must also be aligned for better isolation.
    - For lower isolation requirements, or for secrets that are shared across multiple tenants, cluster-level keys could be used.
  </details>
  <details>
    <summary>Audit Procedure</summary>
    
    - Check whether the Secret Provider configuration is security hardened. Please seek [SOPS](https://github.com/mozilla/sops) and [SealedSecrets](https://github.com/bitnami-labs/sealed-secrets) documentation for how to best implement each solution.
    - When SealedSecrets are employed, pay special attention to the scopes being used.
  </details>

### Resource Isolation

- Ensure additional Flux instances are deployed when mission-critical tenants/workloads must be assured.

  <details>
    <summary>Rationale</summary>

    Sharing the same instances of Flux Components across all tenants including the Platform Admin, will lead to all reconciliations competing for the same resources. In addition, all Flux objects will be placed on the same queue for reconciliation which is limited by the number of workers set by each controller (i.e. `--concurrent=20`), which could cause reconciliation intervals not to be accurately honored.

    For improved reliability, additional instances of Flux Components could be deployed, effectively creating separate "lanes" that are not disrupted by noisy neighbors. An example of this approach would be having additional instances of both Kustomize and Helm controllers that focuses on applying platform level changes, which do not compete with Tenants changes.

    Running multiple Flux instances within the same cluster is supported by means of sharding, please consult the [Flux sharding and horizontal scaling documentation](/flux/cheatsheets/sharding/) for more details.

    To avoid conflicts among controllers while attempting to reconcile Custom Resources, controller types (e.g. `source-controller`) must have be configured with unique label selectors in the `--watch-label-selector` flag.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Check for the existence of additional Flux controllers instances and their respective scopes. Each controller must be started with `--watch-label-selector` and have the selector point to unique label values:
    
    ```sh
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=source-controller | grep -B 5 -A 10 Args
    ```
  </details>

### Node Isolation

- Ensure worker nodes are not being shared across tenants and the Flux components.

  <details>
    <summary>Rationale</summary>

    Pods sharing the same worker node may enable threat vectors which might enable a malicious tenant to have a negative impact on the Confidentiality, Integrity or Availability of the co-located pods.

    The Flux components may have Control Plane privileges while some tenants may not. A co-located pod could leverage its privileges in the shared worker node to bypass its own Control Plane access limitations by compromising one of the co-located Flux components. For cases in which cross-tenant isolation requirements must be enforced, the same risks apply.

    Employ techniques to enforce that untrusted workloads are sandboxed. And, ensure that worker nodes are only shared when within the acceptable risks by your security requirements.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    - Check whether you adhere to [Kubernetes Node Isolation Guidelines](https://kubernetes.io/docs/concepts/security/multi-tenancy/#node-isolation)
    - Check whether there are Admission Controllers/OPA blocking tenants from creating privileged containers.
    - Check whether [RuntimeClass](https://kubernetes.io/docs/concepts/containers/runtime-class/) is being employed to sandbox workloads that may be scheduled in shared worker nodes.
    - Check whether [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) are being used to decrease the likelihood of sharing worker nodes across tenants, or with the Flux controllers. Some cloud providers have this encapsulated as Node Pools.
  </details>

### Network Isolation

- Ensure the Container Network Interface (CNI) being used in the cluster supports Network Policies.

  <details>
    <summary>Rationale</summary>

    Flux relies on Network Policies to ensure that only Flux components have direct access to the source artifacts kept in the Source Controller.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    - Check whether you adhere to [Kubernetes Network Isolation Guidelines](https://kubernetes.io/docs/concepts/security/multi-tenancy/#network-isolation)
    - Confirm that the [Network Policy](/flux/flux-e2e/#fluxs-default-configuration-for-networkpolicy) objects created by Flux are being enforced by the CNI. Alternatively, run a tool such as [Cyclonus](https://github.com/mattfenwick/cyclonus) or [Sonobuoy](https://github.com/vmware-tanzu/sonobuoy) to validate NetworkPolicy enforcement by the CNI plugin on your cluster.
  </details>

### External Endpoint Inputs

Several Flux APIs accept URLs and addresses as input fields that the
controllers dereference on behalf of tenants. In a shared cluster, a tenant
with permission to create these resources can supply an endpoint of their
choosing, exposing the controllers to Server-Side Request Forgery (SSRF).
Three attack types stem from this same input vector and must be addressed
together: credential exfiltration to an attacker-controlled URL, probing of
internal endpoints (including the cloud metadata service) that the tenant
cannot reach directly, and oracle attacks in which the tenant reads response
data echoed back through the controller's status conditions and Events.

Flux deliberately does not implement allowlists or URL parsing logic in the
controllers. The recommendations below combine Kubernetes-native controls
applied at admission, at the controllers' egress, and at the identity layer.
They are complementary and should all be applied.

- Ensure tenants cannot configure arbitrary URLs in Flux resources by
  enforcing a `ValidatingAdmissionPolicy` against the direct URL fields
  exposed by the Flux APIs.

  <details>
    <summary>Rationale</summary>

    The user-facing direct URL inputs are `GitRepository.spec.url`,
    `OCIRepository.spec.url`, `HelmRepository.spec.url`,
    `Bucket.spec.endpoint` and `Bucket.spec.stsEndpoint` in
    `source-controller`; `Provider.spec.address` and `Provider.spec.proxy`
    in `notification-controller`; and `ImageRepository.spec.image` in
    `image-reflector-controller`.

    A `ValidatingAdmissionPolicy` lets the cluster operator declare which
    URL prefixes tenant-managed Flux resources may use, and reject any other
    value at admission time. This is the primary control against credential
    exfiltration via direct URL fields, and a contributing control against
    probing and oracle attacks: requests rejected at admission are never
    issued and produce no response that a tenant could observe.

    The example below allowlists a set of URL prefixes for
    `GitRepository`, `OCIRepository` and `HelmRepository` via a single
    `ConfigMap` parameter, and binds the policy to every namespace
    labelled `toolkit.fluxcd.io/role: tenant`. The `source-controller`
    service account is excluded via a `matchCondition` so that finalizer
    updates are not blocked. The same pattern can be extended to the
    other direct URL fields listed above by adding `resourceRules` and
    adjusting the `variables.url` expression.

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: flux-allowlist
      namespace: flux-system
    data:
      sources: >-
        https://github.com/my-org/
        oci://ghcr.io/my-org/
        oci://ghcr.io/stefanprodan/charts/
        oci://registry-1.docker.io/bitnamicharts/
    ---
    apiVersion: admissionregistration.k8s.io/v1
    kind: ValidatingAdmissionPolicy
    metadata:
      name: flux-source-url-allowlist
    spec:
      failurePolicy: Fail
      paramKind:
        apiVersion: v1
        kind: ConfigMap
      matchConstraints:
        resourceRules:
          - apiGroups:   ["source.toolkit.fluxcd.io"]
            apiVersions: ["*"]
            operations:  ["CREATE", "UPDATE"]
            resources:   ["gitrepositories", "ocirepositories", "helmrepositories"]
      matchConditions:
        - name: exclude-source-controller
          expression: >
            request.userInfo.username != "system:serviceaccount:flux-system:source-controller"
      variables:
        - name: url
          expression: object.spec.url
        - name: prefixes
          expression: params.data.sources.split(' ')
      validations:
        - expression: variables.prefixes.exists(p, variables.url.startsWith(p))
          messageExpression: '"URL " + variables.url + " is not on the allowlist"'
          reason: Invalid
    ---
    apiVersion: admissionregistration.k8s.io/v1
    kind: ValidatingAdmissionPolicyBinding
    metadata:
      name: flux-source-url-allowlist
    spec:
      policyName: flux-source-url-allowlist
      validationActions: ["Deny"]
      paramRef:
        name: flux-allowlist
        namespace: flux-system
        parameterNotFoundAction: Deny
      matchResources:
        namespaceSelector:
          matchExpressions:
            - { key: toolkit.fluxcd.io/role, operator: In, values: [tenant] }
    ```

    A reference fleet using this pattern in production is available at
    [controlplaneio-fluxcd/d2-fleet](https://github.com/controlplaneio-fluxcd/d2-fleet/blob/main/tenants/policies.yaml).
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Confirm that a `ValidatingAdmissionPolicy` and binding exist for the
    relevant resources, that the binding uses
    `validationActions: [ "Deny" ]`, and that its selector covers all
    tenant namespaces:

    ```sh
    kubectl get validatingadmissionpolicy
    kubectl get validatingadmissionpolicybinding
    ```

    Verify enforcement by attempting to create a Flux resource with a URL
    outside the allowlist in a tenant namespace and confirming that
    admission is denied.
  </details>

- Ensure URLs supplied to controllers via Secret or ConfigMap references are
  constrained through multi-tenancy lock-down rather than admission policy.

  <details>
    <summary>Rationale</summary>

    The indirect URL inputs are `Kustomization.spec.kubeConfig.secretRef`
    and `HelmRelease.spec.kubeConfig.secretRef` (cluster URL inside the
    referenced kubeconfig Secret), `Provider.spec.secretRef` (`address`,
    `proxy` and headers inside the referenced Secret), and the
    `proxySecretRef` fields on `GitRepository` and `ImageRepository`.

    A `ValidatingAdmissionPolicy` applied to the Flux resource cannot
    dereference a `secretRef` to inspect its contents, and a separate
    policy applied to `Secret` or `ConfigMap` is fragile because kubeconfig
    payloads are arbitrary YAML inside opaque data keys. The
    [Multi-tenancy Lock-down](#multi-tenancy-lock-down) flags address this
    case by bounding the credentials reachable through a tenant-supplied
    URL: with `--no-cross-namespace-refs=true` the referenced Secret must
    live in the tenant's own namespace, and with the workload identity
    default service account flags (`--default-service-account`,
    `--default-kubeconfig-service-account` and
    `--default-decryption-service-account`, applied per controller as
    described in [Multi-tenancy Lock-down](#multi-tenancy-lock-down)) the
    controller impersonates a tenant-scoped service account when
    authenticating to the (potentially attacker-controlled) target cluster
    or cloud API. Under those flags, an SSRF call through an indirect URL
    field exfiltrates only credentials the tenant could already obtain
    themselves, and there is no cross-tenant escalation. The same flags
    act as a second layer of defense behind the admission policy for
    direct URL fields.

    The minimal example below shows the relevant container args on
    `kustomize-controller`. The full per-controller flag mapping is given
    in [Multi-tenancy Lock-down](#multi-tenancy-lock-down).

    ```yaml
    # kustomize-controller Deployment
    spec:
      template:
        spec:
          containers:
            - name: manager
              args:
                - --no-cross-namespace-refs=true
                - --default-service-account=default
                - --default-kubeconfig-service-account=default
                - --default-decryption-service-account=default
    ```
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Confirm that `--no-cross-namespace-refs=true` and the workload identity
    default service account flags are applied to the relevant controllers
    as described in [Multi-tenancy Lock-down](#multi-tenancy-lock-down):

    ```sh
    kubectl describe pod -n flux-system -l app=kustomize-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=helm-controller | grep -B 5 -A 10 Args
    kubectl describe pod -n flux-system -l app=notification-controller | grep -B 5 -A 10 Args
    ```
  </details>

- Ensure egress from the Flux controllers is restricted at the network
  layer to deny traffic to the link-local range and to cluster-internal
  addresses they do not require.

  <details>
    <summary>Rationale</summary>

    Flux installs a default `allow-egress` `NetworkPolicy` in
    `flux-system` whose `spec.egress` is an empty rule, permitting all
    outbound traffic. Cluster operators must replace or supplement this
    with an actual egress restriction. The probing concern is twofold:
    the controllers can reach destinations that tenant pods cannot
    (such as other tenants' services, or cluster-internal addresses
    denied by the tenant's own `NetworkPolicy`), and the controllers
    occupy a different network and identity position from the tenant,
    which means responses received through the controller may carry
    data that belongs to `flux-system` rather than to the tenant. The
    cloud metadata service (`169.254.169.254`,
    `metadata.google.internal`, Azure IMDS) is the canonical example: a
    tenant pod can usually reach it directly, but only sees its own
    node's metadata; an SSRF call routed through a Flux controller
    returns the controller's node metadata instead, leaking
    platform-side data the tenant could not otherwise observe.

    Restricting controller egress is the primary control against the
    probing attack type. It also contributes to the others: SSRF
    requests blocked at the network layer cannot leak credentials and
    produce no response body to echo back through the status surface.

    The egress restriction should at minimum deny the IPv4 link-local
    range (`169.254.0.0/16`) and the equivalent IPv6 ranges, and any
    in-cluster CIDR that controllers do not legitimately need. Vanilla
    `networking.k8s.io/v1` `NetworkPolicy` is sufficient for this much,
    since the relevant ranges are static and addressable as `ipBlock`
    exceptions, and is supported by every conformant CNI (including AWS
    VPC CNI, Azure CNI / NPM and GKE).

    Restricting public egress to the same allowlist as the admission
    policy is materially harder. Vanilla `NetworkPolicy` has no FQDN
    selector, and the IPs behind hosts such as `github.com` or
    `ghcr.io` are dynamic CDN/anycast addresses that cannot be
    enumerated as CIDRs. FQDN-based egress allowlisting therefore
    requires either a CNI with a richer policy API (for example
    `cilium.io/CiliumNetworkPolicy`, GKE Dataplane V2, Azure CNI
    Powered by Cilium, or Calico Enterprise; on AWS this typically
    means replacing the VPC CNI with Cilium), or a centralised
    cluster-egress gateway that performs the FQDN filtering outside
    the CNI (AWS Network Firewall, commercial cluster-egress products,
    or a self-hosted HTTP proxy such as Envoy or Squid). The trade-off
    between the two approaches is operational footprint versus per-hour
    cost, and both are out of scope for vanilla `NetworkPolicy`.

    The minimal example below denies link-local egress for all pods in
    `flux-system` while permitting all other egress. Operators with a
    CNI-specific policy API in use should express the same denial through
    that API instead, optionally extending it to FQDN or service-identity
    selectors for the source allowlist.

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: deny-link-local-egress
      namespace: flux-system
    spec:
      podSelector: {}
      policyTypes: [Egress]
      egress:
        - to:
            - ipBlock:
                cidr: 0.0.0.0/0
                except:
                  - 169.254.0.0/16
    ```
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Confirm that an egress policy selecting the Flux controller pods
    exists and is enforced by the cluster's CNI:

    ```sh
    kubectl get networkpolicy -n flux-system
    ```

    Repeat the check for any CNI-specific policy resources in use (e.g.
    `kubectl get ciliumnetworkpolicy -n flux-system`). From a debug pod
    under the same egress policy, verify that
    `curl http://169.254.169.254/` and connections to other tenants'
    services fail.
  </details>

- Ensure the Flux controller pods hold no cloud-provider permissions, and
  that the node-level instance metadata service is unreachable from the
  controller pods.

  <details>
    <summary>Rationale</summary>

    The workload identity default service account flags
    (`--default-service-account` for `source-controller`,
    `notification-controller`, `image-reflector-controller` and
    `image-automation-controller`; `--default-kubeconfig-service-account`
    for `kustomize-controller` and `helm-controller`; and
    `--default-decryption-service-account` for `kustomize-controller`)
    govern the tenant-scoped service account that the controller
    impersonates when authenticating to a cloud API on behalf of a Flux
    object. They do not govern the cloud identity attached to the
    controller pod itself via IRSA, GKE Workload Identity, Azure Workload
    Identity or the underlying node's instance profile.

    No Flux pod must hold any cloud-provider permission. All cloud access
    must flow through the workload identity attached to the impersonated
    tenant service account, either named explicitly on the Flux object or
    selected by the default-service-account flags above. If the controller
    pod inherits a cloud identity (from its own service account or from
    the underlying node's instance metadata), an SSRF call to that
    identity source reads the resulting token from the response and
    exfiltrates it through the status surface, regardless of which tenant
    identity was used for the reconciliation. This is the
    metadata-exfiltration variant of the probing attack type.

    The node-level instance metadata service must therefore be unreachable
    from the controller pods. The pod-facing metadata path may still
    exist, but only as a gated workload-identity broker that scopes tokens
    to the impersonated tenant service account; raw access to the
    underlying instance credential must be blocked. This requires both an
    egress restriction at the network layer denying the link-local range
    (item above) and cloud-side hardening at the node level: on AWS set
    the EC2 instance metadata option `httpPutResponseHopLimit` to `1` so
    containers (which add a hop) cannot reach IMDSv2; on GKE enable the
    GKE Metadata Server, which serves only Workload-Identity-scoped tokens
    and intercepts raw IMDS access from pods; on AKS use Azure AD Workload
    Identity, which routes token requests via projected service account
    tokens rather than the node's managed identity.

    The correct pattern is to annotate cloud identity on tenant-namespace
    `ServiceAccount` resources (using the cloud-specific annotation or
    label expected by IRSA, GKE Workload Identity or Azure AD Workload
    Identity) and to leave the `flux-system` service accounts free of any
    such binding. Cloud-side metadata hardening must be applied at the
    node-pool or instance-template level, following the cloud provider's
    own documentation for each of the three platforms; inline examples are
    omitted here to avoid favouring one provider.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    Confirm that no service account in `flux-system` carries cloud workload
    identity bindings (no `eks.amazonaws.com/role-arn` annotation, no
    `iam.gke.io/gcp-service-account` annotation, no
    `azure.workload.identity/client-id` label):

    ```sh
    kubectl get serviceaccount -n flux-system -o yaml | grep -E 'role-arn|gcp-service-account|workload.identity/client-id' || echo "no pod-level cloud identity bindings"
    ```

    Confirm that the nodes hosting the Flux controllers do not grant
    additional cloud permissions through an instance profile or managed
    identity beyond what the cluster itself requires.

    Confirm that the node-level instance credential cannot be retrieved
    from a debug pod scheduled on a flux-system node and sharing the
    controllers' egress policy. The exact request differs per cloud
    provider, but the verification target is the same: the metadata
    interface must refuse to issue a token bound to the node, and
    (where applicable) the only tokens it agrees to issue must be those
    scoped to the pod's workload identity. Follow each cloud provider's
    documentation for the credential-retrieval endpoints to use in this
    test.

    On AWS confirm `httpPutResponseHopLimit` is set to `1` on the node's
    instance metadata options. On GKE confirm the GKE Metadata Server is
    enabled on the node pool. On AKS confirm Azure AD Workload Identity is
    used in place of pod-level managed identity.
  </details>

## Additional Best Practices for Tenant Dedicated Cluster Multi-tenancy

- Ensure tenants are not able to revoke Platform Admin access to their clusters.

  <details>
    <summary>Rationale</summary>

    In environments in which a management cluster is used to bootstrap and manage other clusters, it is important to ensure that a tenant is not allowed to revoke access from the Platform Admin, effectively denying the Management Cluster the ability to further reconcile changes into the tenant's Cluster.

    The Platform Admin should make sure that at the tenant’s cluster bootstrap process, this is taken into the account and a breakglass procedure is in place to recover access without the need to rebuild the cluster.
  </details>
  <details>
    <summary>Audit Procedure</summary>

    - Check whether alerts are in place in case the Remote Apply operations fails.
    - Check the permission set given to the tenant's users and applications is not overly privileged.
    - Check whether there are Admission Controllers/OPA rules blocking changes in Platform Admin's permissions and overall resources.
  </details>
