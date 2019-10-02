# Zato

FROM ubuntu:18.04
LABEL maintainer="Anielkis Herrera <aherrera@zato.io>, Dariusz Suchojad <dsuch@zato.io>"
LABEL Description="Zato's Docker image for cloud environments" Version="3.1.0"

ENV ZATO_BIN /opt/zato/current/bin/zato
ARG zato_py_version

# Install helper programs used during Zato installation
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    curl \
    git \
    libcurl4-openssl-dev \
    software-properties-common \
    supervisor \
    tzdata

# Enable additional repository
RUN add-apt-repository universe

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-3.1-C9B13DF28CFE287D.pgp.txt | apt-key add -

# Add Zato repo and install the package
# update sources and install Zato
ENV ZATO_PY_VERSION=$zato_py_version
RUN add-apt-repository "deb [arch=amd64] https://zato.io/repo/stable/3.1/${ZATO_PY_VERSION:-py3}/ubuntu $(lsb_release -cs) main" && apt-get update && apt-get install -y zato

# Download Dockerize
ENV DOCKERIZE_VERSION v0.11.0
RUN curl -sfL https://github.com/powerman/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-`uname -s`-`uname -m` | install /dev/stdin /usr/local/bin/dockerize

ENV TINI_VERSION v0.18.0
RUN curl -sfL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini | install /dev/stdin /tini

# Install gosu for easy step-down from root
ENV GOSU_VERSION 1.11
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

ENV PG_MAJOR 10
ENV PGBINPATH /usr/lib/postgresql/$PG_MAJOR/bin
ENV PATH $PATH:$PGBINPATH
ENV PGDATA /var/lib/postgresql/data
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Install latest updates
WORKDIR /opt/zato/current
RUN git checkout -- ./requirements.txt && ./update.sh && mkdir -p /var/log/supervisor /var/run/sshd/

USER root

# Copy Docker basic structure
COPY entrypoint.sh /entrypoint.sh
COPY hotdeploy-utility.sh /opt/zato/hotdeploy-utility.sh
COPY enmasse-utility.sh /opt/zato/enmasse-utility.sh
COPY zato.conf /etc/supervisor/conf.d/zato.conf

RUN chmod 755 /entrypoint.sh /opt/zato/hotdeploy-utility.sh /opt/zato/enmasse-utility.sh

EXPOSE 8183 17010 17011 11223
ENTRYPOINT ["/tini", "--"]
CMD [ "/entrypoint.sh" ]
