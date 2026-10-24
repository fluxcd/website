---
title: "Flux SPIFFE mTLS"
linkTitle: "SPIFFE mTLS"
description: "Reference for the SPIFFE ID formats accepted by Flux when authorizing peers for SPIFFE mTLS."
weight: 90
---

Flux supports SPIFFE mTLS for encrypting and authorizing traffic
in the following scenarios:

- [Inter-controller mTLS](/flux/installation/configuration/intercontroller-mtls/):
  Flux controllers authorize each other's SPIFFE IDs for internal traffic.
- [Object Identity](/flux/integrations/object-identity/#spiffe-mtls-annotations):
  The `spiffe.mtls.fluxcd.io/server-ids` annotation authorizes the SPIFFE IDs of
  the external service associated with a Flux object.
- [SPIFFE Broker API](/flux/installation/configuration/object-identity/#spiffe):
  The `--spiffe-broker-id` controller flag authorizes the SPIFFE IDs of the
  SPIFFE Broker API server, which powers object identity.

In all these cases, the SPIFFE IDs must follow the format described below.

- `spiffe://<trust domain>` to authorize any SPIFFE ID in the trust domain.
- `spiffe://<trust domain>/<path>` to authorize an exact SPIFFE ID.
- `spiffe://<trust domain>/<path>/` to authorize a SPIFFE ID prefix. The
  trailing slash implies a prefix.
- `spiffe://self`, `spiffe://self/<path>`, or `spiffe://self/<path>/` to use
  the `self` trust domain, defined below.

For the inter-controller mTLS flags and for `--spiffe-broker-id`, `self` refers to the
trust domain of the controller's own X509-SVID. For `spiffe.mtls.fluxcd.io/server-ids`,
`self` refers to the trust domain of the Flux object's X509-SVID, acquired through the
SPIFFE Broker API.

For more details on the SPIFFE mTLS features available in Flux, follow the
links provided above.
