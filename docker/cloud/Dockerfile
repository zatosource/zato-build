# Zato

FROM ubuntu:18.04
LABEL maintainer="Anielkis Herrera <aherrera@zato.io>, Dariusz Suchojad <dsuch@zato.io>"

ENV ZATO_BIN /opt/zato/current/bin/zato

# Install helper programs used during Zato installation
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    curl \
    git \
    libcurl4-openssl-dev \
    software-properties-common \
    tzdata

# Enable additional repository
RUN add-apt-repository universe

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | apt-key add -

# Add Zato repo and install the package
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/stable/3.0/ubuntu && apt-get update && apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev postgresql-client
ADD zato-3.1.0-python_amd64-bionic.deb /zato-3.1.0-python_amd64-bionic.deb
RUN dpkg -i /zato-3.1.0-python_amd64-bionic.deb ; apt-get install -f -y && rm -f /zato-3.1.0-python3_amd64-bionic.deb

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

# Install latest updates
WORKDIR /opt/zato/current
ADD patcher.sh /opt/zato/current/patcher.sh
RUN git pull && ./update.sh && bash ./patcher.sh && mkdir -p /var/log/supervisor /var/run/sshd/


USER root

# Copy Docker basic structure
COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

EXPOSE 8183 17010 17011 11223
ENTRYPOINT ["/tini", "--"]
CMD [ "/entrypoint.sh" ]
