# Zato

FROM ubuntu:18.04
MAINTAINER Dariusz Suchojad <dsuch@zato.io>

ENV ZATO_BIN /opt/zato/current/bin/zato
ENV DOCKERIZE_VERSION v0.11.0

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
    sudo \
    supervisor \
    vim

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    tzdata

# Enable additional repository
RUN add-apt-repository universe

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo and install the package
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/stable/3.0/ubuntu && apt-get update && apt-get install -y zato

# Install latest updates
WORKDIR /opt/zato/current
RUN git pull && ./update.sh &&  mkdir -p /var/log/supervisor /var/run/sshd/

# Download Dockerize
RUN curl -sfL https://github.com/powerman/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-`uname -s`-`uname -m` | install /dev/stdin /usr/local/bin/dockerize

# Copy Docker basic structure
COPY entrypoint.sh /entrypoint.sh
COPY quickstart-bootstrap.sh /opt/zato/quickstart-bootstrap.sh
COPY supervisord.conf.template /opt/zato/supervisord.conf.template
RUN chmod 755 /entrypoint.sh /opt/zato/quickstart-bootstrap.sh

# Switch to zato user and create Zato environment
USER zato

# Get additional config files and starter scripts
WORKDIR /opt/zato
RUN wget -P /opt/zato -i https://raw.githubusercontent.com/zatosource/zato-build/master/docker/quickstart/filelist && \
  chmod 755 /opt/zato/zato_start_load_balancer \
              /opt/zato/zato_start_server1 \
              /opt/zato/zato_start_server2 \
              /opt/zato/zato_start_web_admin \
              /opt/zato/zato_start_scheduler

USER root
EXPOSE 22 6379 8183 17010 17011 11223
CMD [ "/entrypoint.sh" ]
