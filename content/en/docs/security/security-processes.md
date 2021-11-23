---
title: Security Processes
linkTitle: "Processes"
description: "Flux Security Processes."
---

{{% alert color="info" title="🔐🔍 Security documentation" %}}
Please see [Flux Security documentation](/docs/security) landing page for an overview of Flux security.
{{% /alert %}}

This document defines security reporting, handling, and disclosure information for the Flux project and community.

## Security Advisories

Here is an overview of all our published security advisories.

Date | CVE | Title | Severity | Affected version(s) | Reported by
---- | --- | ----- | -------- | ------------------- | -----------
2021-11-10 | CVE-2021-41254 | [Privilege escalation to cluster admin on multi-tenant Flux](https://github.com/fluxcd/kustomize-controller/security/advisories/GHSA-35rf-v2jv-gfg7) | High | < 0.18.0 | ADA Logics

## Security Process

### Report a Vulnerability

We're very thankful for – and if desired happy to credit – security researchers and users who report vulnerabilities to the Flux community.

- To make a report please email the private security list at <cncf-flux-security@lists.cncf.io> with the details.
  We ask that reporters act in good faith by not disclosing the issue to others.
- You may, but are not required to, encrypt your email to this list using the PGP keys of Security Team members, listed below.
- The Security Team will fix the issue as soon as possible and coordinate a release date with you.
- You will be able to choose if you want public acknowledgement of your effort and how you would like to be credited.

### Security Team

Current Security Team members:

| Name | GitHub | Key URL | Fingerprint |
| -- | -- | -- | -- |
| Scott Rigby | [@scottrigby](https://github.com/scottrigby) | <https://keybase.io/r6by/pgp_keys.asc> | 208D D36E D5BB 3745 A167 43A4 C7C6 FBB5 B91C 1155 |
| Hidde Beydals | [@hiddeco](https://github.com/hiddeco) | <https://keybase.io/hidde/pgp_keys.asc> | C910 7A9B 55A4 DD77 062B 9731 B6E3 6A6A C54A CD59 |

### Handling

- All reports are thoroughly investigated by the Security Team.
- Any vulnerability information shared with the Security Team will not be shared with others unless it is necessary to fix the issue.
  Information is shared only on a need to know basis.
- As the security issue moves through the identification and resolution process, the reporter will be notified.
- Additional questions about the vulnerability may also be asked of the reporter.

### Disclosures

Vulnerability disclosures are emailed to the Flux Dev mailing list <https://lists.cncf.io/g/cncf-flux-dev> and announced publicly.
Disclosures will contain an overview, details about the vulnerability, a fix that will typically be an update, and optionally a workaround if one is available.

We will coordinate publishing disclosures and security releases in a way that is realistic and necessary for end users.
We prefer to fully disclose the vulnerability as soon as possible once a user mitigation is available.
Disclosures will always be published in a timely manner after a release is published that fixes the vulnerability.
