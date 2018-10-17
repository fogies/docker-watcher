#
# This file compiled from Dockerfile.in.
#

FROM ubuntu:14.04

#
# Environment configurations to get everything to play well
#

# Unicode command line
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

# Use bash instead of sh, fix stdin tty messages
RUN rm /bin/sh && ln -s /bin/bash /bin/sh && \
    sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile
#
# Install the packages we need for getting things done
#
# Based on: https://hub.docker.com/_/buildpack-deps/
#

RUN apt-get -qq clean && \
    apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends \
        # From jessie-curl
        # https://github.com/docker-library/buildpack-deps/blob/a0a59c61102e8b079d568db69368fb89421f75f2/jessie/curl/Dockerfile
		ca-certificates \
		curl \
		wget \

        # From jessie-scm
        # https://github.com/docker-library/buildpack-deps/blob/1845b3f918f69b4c97912b0d4d68a5658458e84f/jessie/scm/Dockerfile
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		procps \

        # From jessie
        # https://github.com/docker-library/buildpack-deps/blob/e7534be05255522954f50542ebf9c5f06485838d/jessie/Dockerfile
		autoconf \
		automake \
		bzip2 \
		file \
		g++ \
		gcc \
		imagemagick \
		libbz2-dev \
		libc6-dev \
		libcurl4-openssl-dev \
		libdb-dev \
		libevent-dev \
		libffi-dev \
		libgeoip-dev \
		libglib2.0-dev \
		libjpeg-dev \
		liblzma-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmysqlclient-dev \
		libncurses-dev \
		libpng-dev \
		libpq-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libtool \
		libwebp-dev \
		libxml2-dev \
		libxslt-dev \
		libyaml-dev \
		make \
		patch \
		xz-utils \
		zlib1g-dev \

        # Our common dependencies
        dos2unix \
    && \
    apt-get -qq clean
#
# Install Python
#
# Uses pyenv.
#

ENV PYTHON_VERSION 3.6.6
ENV PYTHON_PIP_VERSION 18.0

# Remove Debian python
RUN apt-get -qq purge -y python.*

# Install pyenv
ENV PYENV_ROOT /root/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN set -ex \
    && curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash \
    && pyenv update \
    && pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    && pyenv rehash

RUN set -ex \
    && python -m pip install --upgrade pip==$PYTHON_PIP_VERSION

################################################################################
# Additional packages we need.
################################################################################
RUN apt-get -qq clean && \
    apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends \
        supervisor \
    && \
    apt-get -qq clean

################################################################################
# Docker and Docker Compose needed for restarting other containers.
#
# Currently hacked to pin to a specific very old version that's on our server.
################################################################################

RUN apt-get install -y -q apt-transport-https ca-certificates
RUN apt-get install -y -q curl ca-certificates
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN mkdir -p /etc/apt/sources.list.d
RUN echo deb [arch=$(dpkg --print-architecture)]
RUN echo deb [arch=$(dpkg --print-architecture)] https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list.d/docker.list
RUN	apt-get update; apt-get install -y -q docker-engine=1.11.2-0~trusty

RUN curl -L https://github.com/docker/compose/releases/download/1.8.0-rc1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# RUN curl -sSL https://get.docker.com/ | DOWNLOAD_URL=https://apt.dockerproject.org/ VERSION=1.11.2-0~trusty sh && \
#    curl -L https://github.com/docker/compose/releases/download/1.8.0-rc1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
#    chmod +x /usr/local/bin/docker-compose

################################################################################
# Set up our entrypoint script.
################################################################################
COPY requirements3.txt requirements3.txt
RUN dos2unix requirements3.txt

COPY docker_watcher/buildbot/buildbot.tac /docker_watcher/buildbot/buildbot.tac
RUN dos2unix /docker_watcher/buildbot/buildbot.tac

COPY docker_watcher/buildbot/master.cfg /docker_watcher/buildbot/master.cfg
RUN dos2unix /docker_watcher/buildbot/master.cfg

COPY docker_watcher/docker_watcher_entrypoint.sh /docker_watcher_entrypoint.sh
RUN dos2unix /docker_watcher_entrypoint.sh && \
    chmod +x /docker_watcher_entrypoint.sh

# Run the wrapper script
CMD ["/docker_watcher_entrypoint.sh"]
