# Fast NONBlOCKING IO to stdout caused by the hack/gen-content.sh script can
# cause Netlify builds to terminate unexpectantly. This forces stdout to block.
BLOCK_STDOUT_CMD           := python -c "import os,sys,fcntl; \
                                           flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
                                           fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"
DOCSY_COMMIT 			   ?= f5a50373c90a5efd71efa1e846d9f28509659ace
DOCSY_COMMIT_FOLDER        := docsy-$(DOCSY_COMMIT)
DOCSY_TARGET               := themes/$(DOCSY_COMMIT_FOLDER)
BOOTSTRAP_SEMVER           ?= 4.6.0
BOOTSTRAP_SEMVER_FOLDER    := bootstrap-$(BOOTSTRAP_SEMVER)
BOOTSTRAP_TARGET           := themes/$(DOCSY_COMMIT_FOLDER)/assets/vendor/$(BOOTSTRAP_SEMVER_FOLDER)
FONT_AWESOME_SEMVER        ?= 5.15.3
FONT_AWESOME_SEMVER_FOLDER := Font-Awesome-$(FONT_AWESOME_SEMVER)
FONT_AWESOME_TARGET        := themes/$(DOCSY_COMMIT_FOLDER)/assets/vendor/$(FONT_AWESOME_SEMVER_FOLDER)

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
	hack/gen-content.sh

serve: gen-content theme ## Spawns a development server.
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build: gen-content theme ## Builds production build.
	hugo \
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
