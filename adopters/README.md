# Flux Adopters

So you and your organisation are using Flux? That's great. We would love to hear from you! 💖

## Adding yourself

In this directory are a number of YAML files where you just need to add an entry for your company and upon merging it will automatically be added to our website.

To add your organisation follow these steps:

1. Fork the [fluxcd/website](https://github.com/fluxcd/website) repository.
1. Clone it locally with `git clone https://github.com/<YOUR-GH-USERNAME>/website.git`.
1. (Optional) Add the logo of your organisation to `adopters/logos`. Good practice is for the logo to be called e.g. `<company>.png`.
1. Find the right `adopters/<project>.yaml` file. If you use e.g. Flux v2, this should be `adopters/flux-v2.yaml`.
1. Add an entry to the YAML file with the `name` of your organisation, `url` that links to its website, and the path to the `logo`. Example:
  ```yaml
      - name: Xenit
        url: https://xenit.se/
        logo: logos/xenit.png
  ```
1. Save the file, then do `git add -A` and commit using `git commit -s -m "Add MY-ORG to adopters"` (commit signoff is required, see [DCO](https://fluxcd.io/contributing/#certificate-of-origin)).
1. Push the commit with `git push origin main`.
1. Open a Pull Request to [fluxcd/website](https://github.com/fluxcd/website) and a preview build will turn up.

Thanks a lot for being part of our community - we very much appreciate it!

### Addendum

`/adopters/logo/logo-generic.png` is a slightly modified Flux logo, it is used when no organisation logo is provided.
