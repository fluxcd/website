serve:
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender

production-build:
	hugo \
		--gc \
		--minify \
		--enableGitInfo

preview-build:
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo

branch-build:
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--gc \
		--minify \
		--enableGitInfo
