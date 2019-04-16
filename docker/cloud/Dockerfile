# Zato

FROM ubuntu:18.04
LABEL maintainer="Anielkis Herrera <aherrera@zato.io>, Dariusz Suchojad <dsuch@zato.io>"

ENV ZATO_BIN /opt/zato/current/bin/zato
ARG ZATO_URL
ARG ZATO_BRANCH
ARG ZATO_COMMIT

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    curl \
    git \
    libcurl4-openssl-dev \
    software-properties-common

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    tzdata

# Enable additional repository
RUN add-apt-repository universe

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | apt-key add -

# Add Zato repo and install the package
# update sources and install Zato
ENV DOCKERIZE_VERSION v0.11.0
RUN if [[ -z ${ZATO_URL} ]];then apt-add-repository https://zato.io/repo/stable/3.0/ubuntu && apt-get update && apt-get install -y zato;else wget -O /tmp/zato.deb ${ZATO_URL} && apt-get install -f -y;fi

# Install latest updates
WORKDIR /opt/zato/current
RUN if [[ -n $ZATO_BRANCH && $ZATO_BRANCH != "main" ]];then git fetch origin --all;git -b checkout $ZATO_BRANCH origin/$ZATO_BRANCH;fi
RUN git pull && if [[ -n $ZATO_COMMIT ]];then git checkout $ZATO_COMMIT;fi
RUN ./update.sh && mkdir -p /var/log/supervisor /var/run/sshd/

# Download Dockerize
RUN curl -sfL https://github.com/powerman/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-`uname -s`-`uname -m` | install /dev/stdin /usr/local/bin/dockerize

# Install gosu for easy step-down from root
ENV GOSU_VERSION 1.11
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

USER root

# Copy Docker basic structure
# COPY zato_start_load_balancer /opt/zato/zato_start_load_balancer
# COPY zato_start_server /opt/zato/zato_start_server
# COPY zato_start_web_admin /opt/zato/zato_start_web_admin
# COPY zato_start_scheduler /opt/zato/zato_start_scheduler
COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh
 # \
 #    /opt/zato/zato_start_load_balancer \
 #    /opt/zato/zato_start_server \
 #    /opt/zato/zato_start_web_admin \
 #    /opt/zato/zato_start_scheduler

EXPOSE 22 6379 8183 17010 17011 11223
CMD [ "/entrypoint.sh" ]
