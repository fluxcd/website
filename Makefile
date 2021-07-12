# Fast NONBlOCKING IO to stdout can
# cause Netlify builds to terminate unexpectantly. This forces stdout to block.
BLOCK_STDOUT_CMD           := python -c "import os,sys,fcntl; \
                                           flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
                                           fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"
DOCSY_COMMIT 			   ?= c36be07b2dcb9aa5aa01bad6ed0f8e111dd0452c
DOCSY_COMMIT_FOLDER        := docsy-$(DOCSY_COMMIT)
DOCSY_TARGET               := themes/$(DOCSY_COMMIT_FOLDER)
BOOTSTRAP_SEMVER           ?= 4.6.0
BOOTSTRAP_SEMVER_FOLDER    := bootstrap-$(BOOTSTRAP_SEMVER)
BOOTSTRAP_TARGET           := themes/$(DOCSY_COMMIT_FOLDER)/assets/vendor/$(BOOTSTRAP_SEMVER_FOLDER)
FONT_AWESOME_SEMVER        ?= 5.15.3
FONT_AWESOME_SEMVER_FOLDER := Font-Awesome-$(FONT_AWESOME_SEMVER)
FONT_AWESOME_TARGET        := themes/$(DOCSY_COMMIT_FOLDER)/assets/vendor/$(FONT_AWESOME_SEMVER_FOLDER)

DEV_IMAGE_REGISTRY_NAME    ?= fluxcd
HUGO_VERSION               ?= 0.84.3
HUGO_IMAGE_BASE_NAME       := website:hugo-$(HUGO_VERSION)-extended
SUPPORT_IMAGE_BASE_NAME    := website:hugo-support
HUGO_IMAGE_NAME            ?= $(DEV_IMAGE_REGISTRY_NAME)/$(HUGO_IMAGE_BASE_NAME)
SUPPORT_IMAGE_NAME         ?= $(DEV_IMAGE_REGISTRY_NAME)/$(SUPPORT_IMAGE_BASE_NAME)
HUGO_BIND_ADDRESS          ?= 127.0.0.1
BUILDER_CLI                := docker
# BUILDER_CLI                := okteto
LYCHEE_IMAGE_NAME          ?= lycheeverse/lychee:202105190720247e4977

help:  ## Display this help menu.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help

theme: $(DOCSY_TARGET) $(BOOTSTRAP_TARGET) $(FONT_AWESOME_TARGET) ## Downloads the Docsy theme and dependencies.

$(DOCSY_TARGET): ## Downloads the Docsy theme.
	mkdir -p themes/
	rm -rf themes/docsy
	curl -Lfs "https://github.com/google/docsy/archive/${DOCSY_COMMIT}.tar.gz" -o "/tmp/${DOCSY_COMMIT_FOLDER}.tar.gz"
	tar -zxf "/tmp/${DOCSY_COMMIT_FOLDER}.tar.gz" --directory themes/
	mv themes/${DOCSY_COMMIT_FOLDER} themes/docsy
	ln -sf docsy themes/${DOCSY_COMMIT_FOLDER}

$(BOOTSTRAP_TARGET): ## Downloads the Docsy bootstrap dependency.
	mkdir -p themes/docsy/assets/vendor
	rm -rf themes/docsy/assets/vendor/bootstrap
	curl -Lfs "https://github.com/twbs/bootstrap/archive/v${BOOTSTRAP_SEMVER}.tar.gz" -o "/tmp/bootstrap-${BOOTSTRAP_SEMVER}.tar.gz"
	tar -zxf /tmp/bootstrap-${BOOTSTRAP_SEMVER}.tar.gz --directory /tmp
	mv /tmp/bootstrap-${BOOTSTRAP_SEMVER} themes/docsy/assets/vendor/bootstrap
	ln -sf bootstrap themes/docsy/assets/vendor/bootstrap-${BOOTSTRAP_SEMVER}

$(FONT_AWESOME_TARGET): ## Downloads the Docsy Font Awesome dependency.
	mkdir -p themes/docsy/assets/vendor
	rm -rf themes/docsy/assets/vendor/Font-Awesome
	curl -Lfs "https://github.com/FortAwesome/Font-Awesome/archive/${FONT_AWESOME_SEMVER}.tar.gz" -o "/tmp/Font-Awesome-${FONT_AWESOME_SEMVER}.tar.gz"
	tar -zxf /tmp/Font-Awesome-${FONT_AWESOME_SEMVER}.tar.gz --directory /tmp
	mv /tmp/Font-Awesome-${FONT_AWESOME_SEMVER} themes/docsy/assets/vendor/Font-Awesome
	ln -sf Font-Awesome themes/docsy/assets/vendor/Font-Awesome-${FONT_AWESOME_SEMVER}

gen-content: ## Generates content from external sources.
	hack/adopters.py
	hack/gen-content.py
	hack/import-flux2-assets.sh

serve: gen-content theme ## Spawns a development server.
	hugo server \
		--bind ${HUGO_BIND_ADDRESS} \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build: gen-content theme ## Builds production build.
	hugo \
		--baseURL $(URL) \
		--gc \
		--minify \
		--enableGitInfo

preview-build: gen-content theme ## Builds a preview build (for e.g. a pull requests).
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

branch-build: gen-content theme ## Builds a Git branch (for e.g. development branches).
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

.PHONY: docker-preview
docker-preview: docker-theme docker-serve

.PHONY: docker-theme
docker-theme:
	docker run -v $(shell pwd):/site -it $(SUPPORT_IMAGE_NAME) \
		make \"MAKEFLAGS=$(MAKEFLAGS)\" theme

.PHONY: docker-serve
docker-serve:
	docker run -v $(shell pwd):/site -p 1313:1313 -it $(SUPPORT_IMAGE_NAME) \
		make \"MAKEFLAGS=$(MAKEFLAGS)\" serve HUGO_BIND_ADDRESS=0.0.0.0

.PHONY: docker-push docker-push-hugo docker-push-support
docker-push: docker-push-hugo docker-push-support

docker-push-hugo: docker-build-hugo
	$(BUILDER_CLI) push $(HUGO_IMAGE_NAME)
#	cd hugo; $(BUILDER_CLI) push -t $(HUGO_IMAGE_NAME)

docker-push-support: docker-build-support
	$(BUILDER_CLI) push $(SUPPORT_IMAGE_NAME)
#	cd docker-support; $(BUILDER_CLI) push -t $(SUPPORT_IMAGE_NAME)

.PHONY: docker-build-support
docker-build-support:
	$(BUILDER_CLI) build -t $(SUPPORT_IMAGE_NAME) docker-support/

.PHONY: docker-build-hugo
docker-build-hugo: hugo
	$(BUILDER_CLI) build -t $(HUGO_IMAGE_NAME) --build-arg HUGO_BUILD_TAGS=extended hugo/

hugo:
	git clone https://github.com/gohugoio/hugo.git --depth 1 -b v$(HUGO_VERSION)

.PHONY: lychee-docker
lychee-docker: gen-content
	docker run --rm -it -e "GITHUB_TOKEN=$GITHUB_TOKEN" -v $$(pwd):/app $(LYCHEE_IMAGE_NAME) "/app/**/*.md"
