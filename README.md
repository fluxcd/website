# fluxcd.io

This repo houses the assets used to build the Flux project's landing page at https://fluxcd.io.

> **Note**: The sources for Flux's documentation, available at https://docs.fluxcd.io, are housed in the main Flux repo at https://github.com/fluxcd/flux. Issues and pull requests for the Flux documentation should be registered at that repo.

## Running the site locally

In order to run the Flux site locally, you need to install:

* [Node.js](https://www.npmjs.com/get-npm)
* The [Hugo](https://gohugo.io) static site generator. Make sure to [install](https://gohugo.io/getting-started/installing/) the "extended" variant of Hugo with support for the [Hugo Pipes](https://gohugo.io/hugo-pipes/introduction/) feature and to check the [`netlify.toml`](./netlify.toml) configuration file for which version of Hugo you should install.

Once those tools are installed, fetch the assets necessary to run the site:

```bash
npm install
```

Then run the site in "server" mode:

```bash
make serve
```

Navigate to http://localhost:1313 to see the site running in your browser. As you make updates to the site, the browser will immediately update to reflect those changes.

## Publishing the site

The Flux website is published automatically by [Netlify](https://netlify.com) when changes are pushed to the `master` branch. The site does not need to be published manually.

### Preview builds

When you submit a pull request to this repository, Netlify builds a "deploy preview" of your changes. You can see that preview by clicking on the **deploy/netlify** link in the pull request window.
