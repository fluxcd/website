---
title: Controller Options
linkTitle: Controller Options
description: "Controller command flags and defaults."
weight: 1
---

To customise the controller options at install time,
please see the [bootstrap customization guide](/flux/installation/configuration/boostrap-customization/).

## Flags

| Name                                  | Type          | Description                                                                                                                                                                              |
|---------------------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--concurrent`                        | int           | The number of concurrent kustomize reconciles. (default 4)                                                                                                                               |
| `--concurrent-ssa`                    | int           | The number of concurrent server-side apply operations. (default 4)                                                                                                                       |
| `--default-service-account`           | string        | Default service account used for impersonation.                                                                                                                                          |
| `--enable-leader-election`            | boolean       | Enable leader election for controller manager. Enabling this will ensure there is only one active controller manager.                                                                    |
| `--events-addr`                       | string        | The address of the events receiver.                                                                                                                                                      |
| `--health-addr`                       | string        | The address the health endpoint binds to. (default ":9440")                                                                                                                              |
| `--http-retry`                        | int           | The maximum number of retries when failing to fetch artifacts over HTTP. (default 9)                                                                                                     |
| `--insecure-kubeconfig-exec`          | boolean       | Allow use of the user.exec section in kubeconfigs provided for remote apply.                                                                                                             |
| `--insecure-kubeconfig-tls`           | boolean       | Allow that kubeconfigs provided for remote apply can disable TLS verification.                                                                                                           |
| `--interval-jitter-percentage`        | uint8         | Percentage of jitter to apply to interval durations. A value of 10 will apply a jitter of +/-10% to the interval duration. It cannot be negative, and must be less than 100. (default 5) |
| `--leader-election-lease-duration`    | duration      | Interval at which non-leader candidates will wait to force acquire leadership (duration string). (default 35s)                                                                           |
| `--leader-election-release-on-cancel` | boolean       | Defines if the leader should step down voluntarily on controller manager shutdown. (default true)                                                                                        |
| `--leader-election-renew-deadline`    | duration      | Duration that the leading controller manager will retry refreshing leadership before giving up (duration string). (default 30s)                                                          |
| `--leader-election-retry-period`      | duration      | Duration the LeaderElector clients should wait between tries of actions (duration string). (default 5s)                                                                                  |
| `--log-encoding`                      | string        | Log encoding format. Can be 'json' or 'console'. (default "json")                                                                                                                        |
| `--log-level`                         | string        | Log verbosity level. Can be one of 'trace', 'debug', 'info', 'error'. (default "info")                                                                                                   |
| `--max-retry-delay`                   | duration      | The maximum amount of time for which an object being reconciled will have to wait before a retry. (default 15m0s)                                                                        |
| `--metrics-addr`                      | string        | The address the metric endpoint binds to. (default ":8080")                                                                                                                              |
| `--min-retry-delay`                   | duration      | The minimum amount of time for which an object being reconciled will have to wait before a retry. (default 750ms)                                                                        |
| `--no-cross-namespace-refs`           | boolean       | When set to true, references between custom resources are allowed only if the reference and the referee are in the same namespace.                                                       |
| `--no-remote-bases`                   | boolean       | Disallow remote bases usage in Kustomize overlays. When this flag is enabled, all resources must refer to local files included in the source artifact.                                   |
| `--override-manager`                  | stringArray   | Field manager disallowed to perform changes on managed resources.                                                                                                                        |
| `--requeue-dependency`                | duration      | The interval at which failing dependencies are reevaluated. (default 30s)                                                                                                                |
| `--sops-age-secret`                   | string        | The name of a Kubernetes secret in the RUNTIME_NAMESPACE containing a SOPS age decryption key for fallback usage.                                                                        |
| `--token-cache-max-size`              | int           | The maximum amount of entries in the LRU cache used for tokens. (default 100, enabled)                                                                                                   |
| `--token-cache-max-duration`          | duration      | The maximum duration for which a token would be considered unexpired. This is capped at 1h. (default 1h)                                                                                 |
| `--watch-all-namespaces`              | boolean       | Watch for custom resources in all namespaces, if set to false it will only watch the runtime namespace. (default true)                                                                   |
| `--watch-configs-label-selector`      | string        | Watch for ConfigMaps and Secrets with matching labels (default 'reconcile.fluxcd.io/watch=Enabled').                                                                                     |
| `--watch-label-selector`              | string        | Watch for resources with matching labels e.g. 'sharding.fluxcd.io/key=shard1'.                                                                                                           |
| `--feature-gates`                     | mapStringBool | A comma separated list of key=value pairs defining the state of experimental features.                                                                                                   |

### Feature Gates

| Name                           | Default Value | Description                                                                                                                                                                                                                                                             |
|--------------------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `CacheSecretsAndConfigMaps`    | `false`       | Configures the caching of Secrets and ConfigMaps by the controller-runtime client. When enabled, it will cache both object types, resulting in increased memory usage and cluster-wide RBAC permissions (list and watch).                                               |
| `DisableFailFastBehavior`      | `false`       | Controls whether the fail-fast behavior when waiting for resources to become ready should be disabled.                                                                                                                                                                  |
| `DisableStatusPollerCache`     | `true`        | Disables the cache of the status poller, which is used to determine the health of the resources applied by the controller. This may have a positive impact on memory usage on large clusters with many objects, at the cost of an increased number of direct API calls. |
| `GroupChangeLog`               | `false`       | Groups together kubernetes objects in log output. Reduces cardinality for Elasticsearch/Opensearch indexing                                                                                                                                                             |
| `ObjectLevelWorkloadIdentity`  | `false`       | Enables the use of object-level workload identity for the controller.                                                                                                                                                                                                   |
| `StrictPostBuildSubstitutions` | `false`       | controls whether the post-build substitutions should fail if a variable without a default value is declared in files but is missing from the input vars.                                                                                                                |
