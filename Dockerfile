ARG HUGO_VERSION
FROM fluxcd/website:hugo-${HUGO_VERSION}-extended

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
RUN npm i

# VOLUME /site	# provided by upstream
# WORKDIR /site
# EXPOSE 1313

ENTRYPOINT []
