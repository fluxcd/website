FROM fluxcd/website:hugo-0.78.2-extended

RUN apk update && \
    apk add --no-cache \
	grep \
	rsync \
	bash \
	make \
	nodejs \
	npm \
	coreutils \
	curl \
	openssh-client \
	jq \
	python3 \
	py3-pip

RUN python3 -m pip install pyyaml
RUN ln -s `which python3` /usr/bin/python

# VOLUME /site	# provided by upstream
# WORKDIR /site
# EXPOSE 1313

ENTRYPOINT []
