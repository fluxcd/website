---
title: "Timetable"
linkTitle: "Migration and Support Timetable"
description: "Flux v1 to v2 migration and support timetable."
weight: 150
hugeTable: true
---

{{% alert color="warning" title="Flux Legacy has reached end of life." %}}
Flux Legacy and Helm Operator have [been
archived](/blog/2022/10/september-2022-update/#flux-legacy-v1-retirement-plan).

We strongly recommend you familiarise yourself with the newest Flux and [migrate as soon as possible](/flux/migration/).
{{% /alert %}}

| Date | Flux 1 | Flux 2 CLI | GOTK[^1] |
| -- | -- | -- | -- |
| Oct 6, 2020 | [Maintenance Mode](https://github.com/fluxcd/website/pull/25)<br><ul><li>Flux 1 releases only include critical bug fixes (which don’t require changing Flux 1 architecture), and security patches (for OS packages, Go runtime, and kubectl). No new features</li><li>Existing projects encouraged to test migration to Flux 2 pre-releases in non-production</li></ul> | Development Mode<br><ul><li>Working to finish parity with Flux 1</li><li>New projects encouraged to test Flux 2 pre-releases in non-production</li></ul> | All Alpha[^2] |
Feb 18, 2021 | Partial Migration Mode<br><ul><li>Existing projects encouraged to migrate to `v1beta1`/`v2beta1` if you only use those features (Flux 1 read-only mode, and Helm Operator)</li><li>Existing projects encouraged to test image automation Alpha in non-production</li></ul> | Feature Parity | Image Automation Alpha. All others reached Feature Parity, Beta |
| June 30, 2021 | Superseded<br><ul><li>All existing projects encouraged to [migrate to Flux 2](/flux/migration/flux-v1-migration/), and [report any bugs](https://github.com/fluxcd/flux2/issues/new/choose)</li><li>Flux 1 Helm Operator code freeze – no further updates except CVEs</li></ul> | Needs further testing, may get breaking changes<br><ul><li>CLI needs further user testing during this migration period</li></ul> | All Beta, Production Ready[^3]<br><ul><li>All Flux 1 features stable and supported in Flux 2</li><li>Promoting Alpha versions to Beta makes this Production Ready</li></ul> |
| May 1, 2022 | Migration and security support only<br><ul><li>Flux 1 releases only include security patches (no bug fixes)</li><li>Maintainers support users with migration to Flux 2 only, no longer with Flux 1 issues</li></ul> | Beta, Production Ready | All Beta, Production Ready |
| November 1, 2022 | Archived<br><ul><li>Flux 1 obsolete, no further releases or maintainer support</li><li>Flux 1 repo archived</li><li>helm-operator repo archived</li></ul> | Public release candidate, Production Ready<br><ul><li>CLI commits to backwards compatibility moving forward</li><li>CLI follows kubectl style backwards compatibility support: +1 -1 MINOR version for server components (e.g., APIs, Controllers, validation webhooks)</li></ul> | All stable, Production Ready |

[^1]: GOTK is shorthand for the [GitOps Toolkit](/flux/components/) APIs and Controllers

[^2]: Versioning: Flux 2 is a multi-service architecture, so requires a more complex explanation than Flux 1:
     - Flux 2 CLI follows [Semantic Versioning](https://semver.org/) scheme
     - The GitOps Toolkit APIs follow the [Kubernetes API versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning) pattern. See [Roadmap](/roadmap/) for component versions.
     - These are coordinated for cross-compatibility: For each Flux 2 CLI tag, CLI and GOTK versions are end-to-end tested together, so you may safely upgrade from one MINOR/PATCH version to another.

[^3]: The GOTK Custom Resource Definitions which are at `v1beta1`, `v1beta2`, `v2beta1` and `v2beta2` and their controllers are considered stable and production ready. Going forward, breaking changes to the beta CRDs will be accompanied by a conversion mechanism.
