# Application for Google Season of Docs 2023

## Status

- [Information about the initiative](https://developers.google.com/season-of-docs/docs)
- Current status of proposal: **Draft**

### [Timeline](https://developers.google.com/season-of-docs/docs/timeline)

## Improving the Flux User Onramp

### About Flux

[Flux](https://fluxcd.io) is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy.

Flux was created in 2016 and helped to formalise GitOps, or "Operations by Pull Request" as industry standard. In 2020 a rewrite of the project was started which helped to drastically modernise the code base and make new use-cases possible.

Flux is a graduated Cloud Native Computing Foundation (CNCF) project, used in production by various organisations and cloud providers.

### Getting Started

If you are interested in participating in Google Season of Docs as a technical writer, please do the following:

1. Join the `#flux-contributors` channel on [CNCF Slack](http://slack.cncf.io/).
1. Review this project proposal and familiarise yourself with the [documentation website](https://fluxcd.io/flux). Particularly the sections `Core Concepts`, `Get Started` and `Installation` are read by our users all them time. Getting a general sense of the structure of the organisation of the documentation will be of help as well.
1. You will need some familiarity with Cloud Native technologies such as [Kubernetes](https://kubernetes.io), so you can more easily understand the problems and background of users.
1. Talk to us on Slack, introduce yourself - we are happy to tell you more.

### Team

- [Flux Org Admins](https://github.com/fluxcd/community/blob/main/ORG-ADMINS): Hidde Beydals, Michael Bridgen, Stefan Prodan
- Project mentor: Daniel Holbach

### About our project

#### The problem

Flux users come with different amounts of background knowledge to the project. Some have been using Kubernetes in earnest for some time, others don't. Understanding the core concepts is critical to your success as a user installing Flux.

Other users are past the hurdles of the initial setup, but are looking at ways to simplify operations or to further automate processes.

#### The projects scope

In this project we would like to accomplish the following:

Part 1: Improve the navigating experience

- Review the information architecture of the Flux documentation
  and assess to which stage of the users' adoption journey the content belongs.
- Write up a plan to recategorise relevant documentation.
- Collect feedback on the new IA. Voices from Flux developers and users should be heard.
- Implement plan, place relevant redirects. Consider link-checking.
- Background information: [#717](https://github.com/fluxcd/website/issues/717), [#718](https://github.com/fluxcd/website/issues/718) (further thoughts [#72](https://github.com/fluxcd/website/issues/72), [#120](https://github.com/fluxcd/website/issues/120))

Part 2: Help understanding core concepts better

- Talk to Flux developers and folks doing online support and get an idea of which Flux concepts are least understood and which basic knowledge is missing when interacting with new Flux users.
- Review Core Concepts documentation, review flow of beginner docs.
- Close potential gap in core concepts documentation. Refer to core concepts in documentation where appropriate.
- Background information: [#111](https://github.com/fluxcd/website/issues/111), [#493](https://github.com/fluxcd/website/issues/493), [#760](https://github.com/fluxcd/website/issues/760), [#783](https://github.com/fluxcd/website/issues/783)

Part 3: Installing Flux - could this be easier?

- Understand overlap between "Installation", cheatsheet entries and current "use-cases" docs.
- Review how other projects deal with this in their documentation. "Tasks" are often a concept used.
- Review Installation docs - should they be broken up? Are references between these and others docs missing, e.g. the cheatsheets and CLI reference?
- Background information: [#523](https://github.com/fluxcd/website/issues/523)

#### Measuring the success

As the Flux developers spend quite a bit of their time on supporting Flux users, and sometimes it takes a bit of time to discover the misunderstanding of a new user, we ideally would like to see the number of support requests go down and get the sense that users can more easily "help themselves".

This will be hard to measure, especially as we are in a growing field and have a growing user-base. Still we want to monitor the number of Github discussions and Slack requests and compare with the previous months.

#### Timeline

Month 1

- Week 1: Familiarise yourself with `fluxcd/website` code and documentation structure. Start reviewing information architecture / structure of docs of other CNCF projects.
- Week 2: Review some more, compare with [previous proposal](https://github.com/fluxcd/website/issues/717) and
  start creating PR for review.
- Week 3: incorporate feedback, test for redirects / broken links.
- Week 4: Ask for feedback from community, implement.

Month 2

- Week 1: Talk to Flux team to figure out contention points and common questions of new users. Review flow of "beginner docs". Start creating plan for where concepts need to be explained more.
- Week 2: If new documentation needs to be written, work with Flux maintainers and contributors to write these up.
- Week 3: Integrate work and ask for feedback from community.
- Week 4: Celebrate success so far - get a nice blog post on the website!

Month 3

- Week 1: Review overlap between Install docs, cheatsheet entries and use-cases. Compare with other projects.
- Week 2: Hopefully with what's been done in Month 1, it will be easier to distinguish Day 1 from Day 2 tasks. If there is a lot more work to be done to e.g. break up pieces into "tasks", maybe focus on low-hanging fruit instead.
- Week 3: Ask for feedback again, publish.
- Week 4: Tidy up potential loose ends. Celebrate!

#### Project budget

| Budget item | Amount | Running Total | Notes/justifications
| ----------- | ------ | ------------- | --------------------
| Technical writer audit, update, test, and publish new documentation | 7500.00 | 7500.00 |
| Project t-shirts (10 t-shirts) | 250.00 | 7750.00 |
| TOTAL | 7750.00 | |

## Additional information

**Previous experience with technical writers or documentation:** End of November 2021 the Celeste Horgan of the CNCF Tech Docs team [assessed the Flux documentation](https://github.com/cncf/techdocs/blob/main/assessments/0005-fluxcd.md). Some of the [identified areas were addressed](https://github.com/orgs/fluxcd/projects/3) since then. Some of the findings are key issues we want to tackle as part of this proposal.

**Previous participation in Google Season of Docs, Google Summer of Code or others:** ...

Flux has not participated in any of these initiatives, so we are looking forward to being part of this (if chosen) and work together with the wider Docs community!
