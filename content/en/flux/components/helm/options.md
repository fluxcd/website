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
| `--concurrent`                        | int           | The number of concurrent HelmRelease reconciles. (default 4)                                                                                                                             |
| `--default-service-account`           | string        | Default service account used for impersonation.                                                                                                                                          |
| `--enable-leader-election`            | boolean       | Enable leader election for controller manager. Enabling this will ensure there is only one active controller manager.                                                                    |
| `--events-addr`                       | string        | The address of the events receiver.                                                                                                                                                      |
| `--graceful-shutdown-timeout`         | int           | The duration given to the reconciler to finish before forcibly stopping. (default 600s)                                                                                                  |
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
| `--oom-watch-interval`                | duration      | The interval at which the OOM watcher will check for memory usage. Requires feature gate 'OOMWatch' to be enabled. (default 500ms)                                                       |
| `--oom-watch-memory-threshold`        | unit8         | The memory threshold in percentage at which the OOM watcher will trigger a graceful shutdown. Requires feature gate 'OOMWatch' to be enabled. (default 95)                               |
| `--oom-watch-max-memory-path`         | string        | The path to the cgroup memory limit file. Requires feature gate 'OOMWatch' to be enabled. If not set, the path will be automatically detected.                                           |
| `--oom-watch-current-memory-path`     | string        | The path to the cgroup current memory usage file. Requires feature gate 'OOMWatch' to be enabled. If not set, the path will be automatically detected.                                   |
| `--requeue-dependency`                | duration      | The interval at which failing dependencies are reevaluated. (default 30s)                                                                                                                |
| `--snapshot-digest-algo`              | string        | The algorithm to use to calculate the digest of Helm release storage snapshots. (default "sha256")                                                                                       |
| `--token-cache-max-size`              | int           | The maximum amount of entries in the LRU cache used for tokens. (default 100, enabled)                                                                                                   |
| `--token-cache-max-duration`          | duration      | The maximum duration for which a token would be considered unexpired. This is capped at 1h. (default 1h)                                                                                 |
| `--watch-all-namespaces`              | boolean       | Watch for custom resources in all namespaces, if set to false it will only watch the runtime namespace. (default true)                                                                   |
| `--watch-label-selector`              | string        | Watch for resources with matching labels e.g. 'sharding.fluxcd.io/key=shard1'.                                                                                                           |
| `--feature-gates`                     | mapStringBool | A comma separated list of key=value pairs defining the state of experimental features.                                                                                                   |

### Feature Gates

| Name                         | Default Value | Description                                                                                                                                                                                                                                   |
|------------------------------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `AdoptLegacyReleases`        | `true`        | Enables the adoption of the historical Helm release based on the status fields from a v2beta1 HelmRelease object. This is enabled by default to support an upgrade path from v2beta1 to v2beta2 without the need to upgrade the Helm release. |
| `AllowDNSLookups`            | `false`       | Allows the controller to perform DNS lookups when rendering Helm templates. This is disabled by default, as it can be a security risk.                                                                                                        |
| `CacheSecretsAndConfigMaps`  | `false`       | Configures the caching of Secrets and ConfigMaps by the controller-runtime client. When enabled, it will cache both object types, resulting in increased memory usage and cluster-wide RBAC permissions (list and watch).                     |
| `DisableChartDigestTracking` | `false`       | Disables the tracking of digest changes for Helm OCI charts. When set to `true`, the controller will not append the OCI digest to the chart version in `Chart.yaml`.                                                                          |
| `ObjectLevelWorkloadIdentity` | `false`       | Enables the use of object-level workload identity for the controller.                                                                                                                                                                        |
| `OOMWatch`                   | `false`       | Enables the OOM watcher, which will gracefully shut down the controller when the memory usage exceeds the configured limit. This is disabled by default.                                                                                      |
