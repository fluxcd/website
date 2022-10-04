---
author: developer-guy
date: 2022-10-04 11:30:00+00:00
title: Prove the Authenticity of the OCI Artifacts
description: "We'll talk about integration of the cosign tool, which is a tool for signing and verifying the given container images, blobs, etc, that we used to prove the authenticity of the OCI Artifacts we manage through the OCIRepository resources."
url: /blog/2022/10/prove-the-authenticity-of-the-oci-artifacts
tags: [oci]
resources:
- src: "**.{png}"
  title: "Image #:counter"
---

Software supply chain attacks are one of the most critical risks threatening today's software, and it has collapsed like a dark cloud on the software industry. The Flux community is one of those communities that always takes precautions against these threats. While providing the measures I mentioned primarily for their own products, they also provided users with awareness-raising articles on these issues. You can find all of Flux's articles on safety here. I strongly recommend you to read these articles. And they did not stop here, they also introduced features in their products that could protect users against these threats, and today we will talk about one of these features.  