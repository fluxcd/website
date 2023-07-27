ARG HUGO_VERSION
FROM fluxcd/website:hugo-${HUGO_VERSION}-extended
COPY --from=golang:1.19-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"

RUN apk update && \
	apk add --no-cache \
	bash \
	coreutils \
	curl \
	gcc \
	grep \
	jq \
	libc-dev \
	libffi-dev \
	linux-headers \
	make \
	nodejs \
	npm \
	openssh-client \
	py3-pip \
	python3 \
	python3-dev \
	rsync

COPY requirements.txt /tmp
RUN python3 -m pip install -r /tmp/requirements.txt
RUN ln -s `which python3` /usr/bin/python
COPY package.json package-lock.json /site/
RUN npm i
RUN git config --global --add safe.directory /site

# VOLUME /site	# provided by upstream
# WORKDIR /site
# EXPOSE 1313

ENTRYPOINT []
