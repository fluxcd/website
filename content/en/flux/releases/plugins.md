---
title: "Flux plugin releases"
linkTitle: "Plugins"
description: "Flux plugin release documentation."
weight: 20
---

The official Flux CLI plugins have a release lifecycle that is detached from
the Flux distribution lifecycle.

The Flux distribution pins the Flux controllers and the main `flux` CLI to a
coherent set of versions. Official plugins are released independently from that
distribution cycle.

Plugin releases are shipped whenever new plugin features or fixes are ready. In
addition, the Flux project ships plugin releases together with each Flux
distribution minor release, so plugin dependencies can be aligned with the
controllers and the main `flux` CLI at that point in time.

Because plugins can be released between Flux distribution releases, users should
not expect plugin minor versions to match the Flux distribution minor version.
For example, a plugin minor version may advance after a Flux distribution minor
release if a new plugin feature is shipped the following week.

Official plugin repositories do not maintain release branches. Changes are
merged into `main`, and releases are cut from signed SemVer tags on `main`.
