# Fast NONBlOCKING IO to stdout can
# cause Netlify builds to terminate unexpectantly. This forces stdout to block.
BLOCK_STDOUT_CMD           := python -c "import os,sys,fcntl; \
                                           flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
                                           fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"
DEV_IMAGE_REGISTRY_NAME    ?= fluxcd
HUGO_VERSION               ?= $(shell grep HUGO_VERSION netlify.toml | cut -d'"' -f2)
HUGO_IMAGE_BASE_NAME       := website:hugo-$(HUGO_VERSION)-extended
SUPPORT_IMAGE_BASE_NAME    := website:hugo-support
HUGO_IMAGE_NAME            ?= $(DEV_IMAGE_REGISTRY_NAME)/$(HUGO_IMAGE_BASE_NAME)
SUPPORT_IMAGE_NAME         ?= $(DEV_IMAGE_REGISTRY_NAME)/$(SUPPORT_IMAGE_BASE_NAME)
HUGO_BIND_ADDRESS          ?= 127.0.0.1
BUILDER_CLI                := docker
# BUILDER_CLI                := okteto
LYCHEE_IMAGE_NAME          ?= lycheeverse/lychee:202105190720247e4977
YQ_VERSION                 ?= v4.34.2
BRANCH                     ?= main

REPO_ROOT := $(shell git rev-parse --show-toplevel)
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
BIN_DIR := $(REPO_ROOT)/bin

help:  ## Display this help menu.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help

prereqs:
	npm install
	python3 -m pip install -r requirements.txt

.PHONY: yq
yq: $(BIN_DIR)/yq-$(YQ_VERSION)

$(BIN_DIR)/yq-$(YQ_VERSION):
	mkdir -p $(BIN_DIR) && wget https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_$(OS)_$(shell go env GOARCH) -O $(BIN_DIR)/yq-$(YQ_VERSION) && \
	    chmod +x $(BIN_DIR)/yq-$(YQ_VERSION) && \
	    cp $(BIN_DIR)/yq-$(YQ_VERSION) $(BIN_DIR)/yq

gen-content: yq ## Generates content from external sources.
	hack/gen-content.py
	hack/import-calendar.py
	PATH=$(BIN_DIR):$(PATH) BRANCH=$(BRANCH) hack/import-flux2-assets.sh

serve: gen-content prereqs ## Spawns a development server.
	hugo server \
		--bind ${HUGO_BIND_ADDRESS} \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build: gen-content prereqs ## Builds production build.
	hugo \
		--baseURL $(URL) \
		--gc \
		--minify \
		--enableGitInfo

preview-build: gen-content prereqs ## Builds a preview build (for e.g. a pull requests).
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

branch-build: gen-content prereqs ## Builds a Git branch (for e.g. development branches).
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--environment branch \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

.PHONY: docker-preview
docker-preview: docker-serve

.PHONY: docker-serve
docker-serve:
	docker run -v $(shell pwd):/site -p 1313:1313 -it $(SUPPORT_IMAGE_NAME) \
		make \"MAKEFLAGS=$(MAKEFLAGS)\" serve HUGO_BIND_ADDRESS=0.0.0.0 GITHUB_TOKEN=$(GITHUB_TOKEN) BRANCH=$(BRANCH)

.PHONY: docker-push docker-push-hugo docker-push-support
docker-push: docker-push-hugo docker-push-support

docker-push-hugo: docker-build-hugo
	$(BUILDER_CLI) push $(HUGO_IMAGE_NAME)
#	cd hugo; $(BUILDER_CLI) push -t $(HUGO_IMAGE_NAME)

docker-push-support: docker-build-support
	$(BUILDER_CLI) push $(SUPPORT_IMAGE_NAME)
#	$(BUILDER_CLI) push -t $(SUPPORT_IMAGE_NAME)

.PHONY: docker-build-support
docker-build-support:
	$(BUILDER_CLI) build --build-arg HUGO_VERSION=${HUGO_VERSION} -t $(SUPPORT_IMAGE_NAME) .

.PHONY: docker-build-hugo
docker-build-hugo: hugo
	$(BUILDER_CLI) build --build-arg HUGO_VERSION=${HUGO_VERSION} -t $(HUGO_IMAGE_NAME) --build-arg HUGO_BUILD_TAGS=extended hugo/

hugo:
	git clone https://github.com/gohugoio/hugo.git --depth 1 -b v$(HUGO_VERSION)

.PHONY: lychee-docker
lychee-docker: gen-content
	docker run --rm -it -e "GITHUB_TOKEN=$GITHUB_TOKEN" -v $$(pwd):/app $(LYCHEE_IMAGE_NAME) "/app/**/*.md"

print-hugo-version:
	echo hugo_version=$(HUGO_VERSION)

print-repo-owner:
	echo repo_owner=$(DEV_IMAGE_REGISTRY_NAME)
