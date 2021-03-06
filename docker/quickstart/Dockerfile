# Zato

FROM ubuntu:20.04
LABEL maintainer="Anielkis Herrera <aherrera@zato.io>, Dariusz Suchojad <dsuch@zato.io>"

ENV ZATO_BIN /opt/zato/current/bin/zato
ENV TZ=GMT
ENV DEBIAN_FRONTEND=noninteractive

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    curl \
    git \
    htop \
    libcurl4-openssl-dev \
    mc \
    redis-server \
    software-properties-common \
    ssh \
    wget \
    sudo \
    supervisor \
    vim \
    libpq-dev \
    gnupg \
    whois

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/* && apt-get update -y
RUN ln -fs /usr/share/zoneinfo/GMT /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Enable additional repository
RUN add-apt-repository universe

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-3.2-48849AAD40BCBB0E.pgp.txt | sudo apt-key add -

# Add Zato repo and install the package
# update sources and install Zato
# ENV ZATO_PY_VERSION=$zato_py_version
RUN add-apt-repository "deb [arch=amd64] https://zato.io/repo/stable/3.2/ubuntu $(lsb_release -cs) main" && apt-get update && apt-get install -y zato

# Install latest updates
WORKDIR /opt/zato/current
RUN git pull && ./update.sh &&  mkdir -p /var/log/supervisor /var/run/sshd/
RUN ./bin/pip install supervisord-dependent-startup && sed -i '/^\[include\]/i [eventlistener:dependentstartup]\ncommand=python -m supervisord_dependent_startup\nautostart=true\nautorestart=unexpected\nstartretries=0\nexitcodes=0,3\nevents=PROCESS_STATE\n' /etc/supervisor/supervisord.conf

# Download Dockerize
ENV DOCKERIZE_VERSION v0.11.8
RUN curl -sfL https://github.com/powerman/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-`uname -s`-`uname -m` | install /dev/stdin /usr/local/bin/dockerize

# Install gosu for easy step-down from root
ENV GOSU_VERSION 1.12
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

USER root

# Copy Docker basic structure
COPY import-utility.sh /opt/zato/import-utility.sh
COPY supervisord.conf.template /opt/zato/supervisord.conf.template
COPY update_password.config /opt/zato/update_password.config
COPY zato_start_load_balancer /opt/zato/zato_start_load_balancer
COPY zato_start_server1 /opt/zato/zato_start_server1
COPY zato_start_server2 /opt/zato/zato_start_server2
COPY zato_start_dashboard /opt/zato/zato_start_dashboard
COPY zato_start_scheduler /opt/zato/zato_start_scheduler
COPY quickstart-bootstrap.sh /opt/zato/quickstart-bootstrap.sh
COPY get-credentials /opt/zato/get-credentials
COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh \
    /opt/zato/*.sh \
    /opt/zato/get-credentials \
    /opt/zato/zato_start_load_balancer \
    /opt/zato/zato_start_server1 \
    /opt/zato/zato_start_server2 \
    /opt/zato/zato_start_dashboard \
    /opt/zato/zato_start_scheduler && chown zato. /opt/zato/update_password.config

EXPOSE 22 6379 8183 17010 17011 11223
CMD [ "/entrypoint.sh" ]
