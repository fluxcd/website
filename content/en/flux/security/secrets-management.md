---
title: "Secrets Management"
linkTitle: "Secrets Management"
description: "Managing Secrets in a GitOps way using Flux."
weight: 140
---

## Introduction

Flux improves the application deployment process by continuously reconciling a
desired state, defined at a source, against a target cluster. One of the challenges
with this process is its dependency on secrets, that must not be stored in plain-text
like the rest of the desired state.

Secrets are sensitive information that an application needs to operate such as:
credentials, passwords, keys, tokens and certificates. Managing secrets declaratively
needs to be done right because of its broad security implications.

We will cover the mechanisms supported by Flux, as well as the security principles,
concerns and techniques to consider when managing secrets with Flux.

### What's inside the toolbox?

First of all, let's go through the different options supported by Flux and Kubernetes.

Nowadays there are a multitude of secret management options. Some are available in-cluster,
directly in the comfort of your Kubernetes cluster, and others that are provided from
out-of-cluster, for example a Cloud based KMS.

#### Kubernetes Secrets

Kubernetes has a [built-in mechanism][kubernetes secrets] to store and manage secrets. The secrets
are stored in etcd either in plain-text or [encrypted][etcd encryption].

They are the vanilla offering, which is used during `flux bootstrap`, for example, to store your
SSH Deploy Keys. Unless when the initial Flux source supports [contextual authorization],
in which case no secrets are required.

Storing plain-text secrets in your desired state is not recommended, so apart from the secret
used to authenticate against your initial source, Flux users should not manage these. Instead,
they should rely mostly on other mechanisms covered below.

#### Secrets Decryption Operators

Sometimes referred to as Encrypted Secrets, Secrets Decryption Operators enable secrets to be stored
in ciphertext as Kubernetes resources within a Flux source. They are deployed into the cluster by
Flux in their original CustomResourceDefinition (CRD) form, which is later used by its Secret
Decryption Operator to decrypt those secrets and generate a Kubernetes Secret.

This is transparent to the consuming applications, making it a quite suitable approach to retrofit
into an existing setup. An example of a Secret Decryption Operator is [Sealed Secrets].

Storing encrypted secrets in Git repositories enables configuration versioning to leverage the
same practices used for managing, versioning and releasing application and/or infrastructure
when using declarative "everything as code", for example pull-requests, tags and branch
strategies.

Note that some sources may keep a history of the encrypted Secrets (e.g. `GitRepository`)
through time. Increasing the impact when old encryption keys are leaked, especially when
other security measures are not in place (e.g. secret rotation) or when long-lived secrets
are being handled (e.g. Public TLS Certs).

Notice that secrets can be stored in any Source type supported by Flux, such as [Buckets] and
[OCI repositories].

Flux specific guides on using Secrets Decryption Operators:

- [Bitnami Sealed Secrets](/flux/guides/sealed-secrets/)

#### Using Flux to decrypt Secrets on-demand

Flux has the ability to decrypt secrets stored in Flux sources by itself, without the need of
additional controllers installed in the cluster. The approach relies on keeping in Flux sources
encrypted Kubernetes Secrets, which are decrypted on-demand with [SOPS], just before they are
deployed into the target clusters.

This approach is more flexible than using [Sealed Secrets], as [SOPS] supports cloud-based Key
Management Services of the major cloud providers (Azure KeyVault, GCP KMS and AWS KMS), HashiCorp
Vault, as well as "off-line" decryption using Age and PGP.

This mechanism supports [kustomize-secretgenerator] which ensures that dependent workloads will
reload automatically and start using the latest version of the secret. Notice that most approaches
that are based on Kubernetes Secrets would require something like [stakater/Reloader] to achieve
the same result. The [Kubernetes blog][kustomization-secretgenerator] explains quite well how this works.

The security concerns of this approach are similar to the Secrets Decryption Operators, but with
the added benefit that no additional controllers are required, therefore reducing resources consumption
and the attack surface. When using external providers (e.g. KMS, Vault), remember that they can become
a single point of failure, if they are deleted by mistake (or unavailable by extended periods) this
could impact your solution.

Flux supports the two main names in Encrypted Secrets and has specific how-to guides for them:

- [Mozilla SOPS Guide](/flux/guides/mozilla-sops/)
- [Secrets decryption](/flux/components/kustomize/kustomizations/#decryption)

#### Secrets Synchronized by Operators

The source of truth for your secrets can reside outside of the cluster, and then be synchronised
into the cluster as Kubernetes Secrets by operators. Much like encrypted secrets, this process
is transparent to the workloads in the cluster.

Two examples of this type of operator are [1Password Operator] and [External Secrets Operator].
But given their nature, Flux is able to support any operator that manages Kubernetes secrets.

This approach provides a level of redundancy by default, as secrets are kept at both the cluster
and the remote source, so small failures can go undetected. It supports hybrid workloads
quite well, when some secrets have to be shared with applications that are not Kubernetes-based.

When using mutable secrets, it could be hard for Flux or the dependent applications to know
whether they are using the latest version of a given secret. In such cases, immutable secrets,
where the name also contains the version of the secret, may help.

Take into account the loading times when provisioning a new cluster, as that can become a
bottleneck slowing down the provisioning time as the number of secrets increases.

Flux supports all operators that provide this functionality.

#### Secrets mounted via CSI Drivers

Another way to bring external secrets into Kubernetes, is the use of CSI Drivers,
which mounts secrets as files directly into a Pod filesystem, instead of generating
native Kubernetes Secrets.

Due to the way it works, the secrets are not accessible within the Kubernetes Control
Plane, so although you can use it with your workloads, it won't work when providing
to CustomResourceTypes (CRDs) that need a reference to a secret
(e.g. `.spec.secretRef.name` in `GitRepository`).

With CSI Drivers, the mounting takes place at Pod starting time, so issues accessing
the external source of the secrets may be more impactful.

Here are a few CSI providers:

- [HashiCorp Vault](https://github.com/hashicorp/vault-csi-provider)
- [Azure KeyVault](https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html)
- [GCP CSI Driver](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp)

#### Direct access to out-of-cluster Secrets

Direct access to a secret management solution that resides outside of a Kubernetes
cluster is also an option. Which could be a useful alternative when lifting and
shifting legacy applications that already depend on such approach.

Here the secret management solution will become a single point of failure,
expect issues when it goes temporarily unavailable and make sure to have disaster recovery plans.
Also observe throttling limits of cloud solutions, given that different applications
may be targeting the same Secret Manager, without a rate limiter across all of them,
this could easily lead to an outage at scale.

Flux currently does not directly fetch secrets from out-of-cluster solutions, in the
same way that most Kubernetes native tools don't, therefore this approach may need to
be combined with things such as Secrets Synchronized by Operators. However, this will
not block the ability of your applications to do so.

### Big Picture - Things to consider

Once you are aware of the different tools in the toolbox, it is important to align them
with your actual requirements, taking into account some key points:

#### Expiration and Rotation

Secrets should have an expiration time, and ideally such expiration should be enforced,
so that the potential of leakage has a well-defined risk window.

To facilitate the uninterrupted use of the dependent applications, rotation should be
automated taking into account that at times different versions of the same secret
(old and new) may need to be supported at the same time - e.g. whilst validating a
new version of the application that is being deployed.

Both secrets can remain active during a time window, but once the new version is
validated after deployment, the previous secrets can be safely decommissioned.
Cloud KMS solutions tend to provide secret versioning built-in.

#### Access Management and Auditing

Access to secrets should be restricted to the servers and applications within the environment
they need to be accessed. The same goes for users and service accounts.

When considering the different solutions, it is important to note how they hang together
and what the gaps are. If you have a strong requirement for access and auditing controls,
having a well-defined api-server auditing in place, together with tight RBAC policies in your
cluster is only part of the problem. Also take into account how those secrets are sourced,
stored and handled. Maybe having secrets stored (even if in encrypted form) in an easily
accessible Flux source that has a loosely defined RBAC and no auditing in place may not meet
such requirements.

#### Least Privileged and Segregation of duties

The scope of each secret must be carefully considered to decrease the blast radius in
case of breach. A trade-off must be reached to attain a balance between the two extremes:
having a single secret that has all the access, versus having too many secrets that are
always used in combination.

Sharing the same secret across different scopes, just because they have the same permissions
may lead to disruption if such secret needs to be quickly rotated.

#### Disaster Recovery

The entire provisioning of your infrastructure and application must take into account
break the glass procedures that are secure, provide relevant security controls (e.g. auditing)
and cannot be misused to bypass other processes (e.g. Access Management).

Around disaster recovery scenarios, consider how they align with your Availability and
Confidentiality requirements.

#### Don't co-locate ciphertext with encryption keys

It should go without saying, but never place secrets together with keys that can provide privilege
escalation routes. For example, if you store the decryption key for your secrets in GitHub secrets,
and all your encrypted secrets are stored in the same repository, a single GitHub account
(with enough access) compromised is enough for all your secrets to be decrypted.

Instead, segregate encryption keys from ciphertext and understand what needs to be compromised
for the data to be at risk.

#### Single Points of Failure

Identify all potential single points of failure and ensure that there is a way around them.
If all your secrets are encrypted using an encryption key stored in Vault, and due to a major
failure your Vault instance is completely lost, and no backup is to be found, the encrypted
secrets are now useless. Therefore, think big picture, and ensure that each step of the way
has a redundancy and that process is regularly exercised.

The same goes for temporary single points of failure. If you rely on a Key Hierarchy Architecture
based on a cloud KMS to provision an on-premises cluster/application, consider the impact
they would have in case of a failure pre, mid or post deploy (of either cluster or applications).

#### Ephemeral or Single-use Secrets

The easiest type of secrets to manage are the ones that ephemeral; context-bound and time-bound.
However, they are not supported by all use-cases. Whenever they are, prioritise their use over
static or long-lived secrets.

An example of an ephemeral secret that is time-bound, is a token provided by cloud providers to
any application running within a given Cloud Machine. Those tokens are generated automatically,
and have a short expiration time. In some cases you can even tie them to a network boundary,
meaning that even if they get breached, they won't be able to be used outside the current
context.

Flux supports [contextual authorization] for the major Cloud Providers, be aware of the supported
features and use them whenever possible.

#### Detect "chicken and egg" scenarios

Flux won't protect you from yourself. On a running cluster, it is quite easy to incrementally fall
into the trap of building a non-provisionable cluster. For example, if your first Kustomization
depends on a CustomResourceType (CRD) to deploy a secret, which is only deployed as part of another
Kustomization, Flux may not be able to redeploy your sources from scratch on a new cluster.

Make sure that your pipeline identifies and tests such scenarios. Automate the provisioning of clusters
that can test the entire E2E of your deployment process, and ensure that it is executed regularly.

### Summary

Flux supports a wide range of Secret Management solutions. And it is up to its users
to define what works best for their use case. This subject isn't easy, and due diligence
is important to ensure the appropriate level of security controls are in place.

Overall, none of the approaches covered above are inherently secure or insecure, but they
are rather part of a big picture in which what matters the most is the weakest link
and how it all hangs together. As with all things around security, a layered approach is
recommended.

Take into account your threat model, availability and resilience requirements
when deciding what works best for you, and rest assured that a combination of some of
the above will make more sense, especially when disaster recovery and break the glass
scenarios are considered.

[kubernetes secrets]: https://kubernetes.io/docs/concepts/configuration/secret/
[etcd encryption]: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
[Sealed Secrets]: https://github.com/bitnami-labs/sealed-secrets
[SOPS]: https://github.com/mozilla/sops
[1Password Operator]: https://github.com/1Password/onepassword-operator
[External Secrets Operator]: https://github.com/external-secrets/external-secrets
[AWS Key Hierarchy]: https://aws.amazon.com/blogs/security/benefits-of-a-key-hierarchy-with-a-master-key-part-two-of-the-aws-cloudhsm-series/
[contextual authorization]: /flux/security/contextual-authorization/
[Buckets]: /flux/components/source/buckets/
[OCI Repositories]: /flux/components/source/ocirepositories/
[stakater/Reloader]: https://github.com/stakater/Reloader
[kustomize-secretgenerator]: /flux/components/kustomize/kustomizations/#kustomize-secretgenerator
[kustomization-secretgenerator]: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomizations/#secretgenerator
