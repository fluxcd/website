# Fast NONBlOCKING IO to stdout caused by the hack/gen-content.sh script can
# cause Netlify builds to terminate unexpectantly. This forces stdout to block.
BLOCK_STDOUT_CMD        := python -c "import os,sys,fcntl; \
                                        flags = fcntl.fcntl(sys.stdout, fcntl.F_GETFL); \
                                        fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags&~os.O_NONBLOCK);"

gen-content: ## Generates content from external sources.
	hack/gen-content.sh

container-gen-content: ## Generates content from external sources within a container (equiv to gen-content).
	$(CONTAINER_RUN) $(CONTAINER_IMAGE) hack/gen-content.sh

serve:
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build:
	hack/gen-content.sh
	hugo \
		--gc \
		--minify \
		--enableGitInfo

preview-build:
	hack/gen-content.sh
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

branch-build:
	hack/gen-content.sh
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo
