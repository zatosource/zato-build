# Zato

FROM ubuntu:18.04
MAINTAINER Dariusz Suchojad <dsuch@zato.io>

ENV ZATO_BIN /opt/zato/current/bin/zato

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
ENV DOCKERIZE_VERSION v0.11.0
RUN apt-add-repository https://zato.io/repo/stable/3.0/ubuntu && apt-get update && apt-get install -y zato

# Install latest updates
WORKDIR /opt/zato/current
RUN git pull && ./update.sh &&  mkdir -p /var/log/supervisor /var/run/sshd/

# Download Dockerize
RUN curl -sfL https://github.com/powerman/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-`uname -s`-`uname -m` | install /dev/stdin /usr/local/bin/dockerize

# postgresql
RUN apt install -y postgresql postgresql-contrib postgresql-client
USER postgres
ENV PG_MAJOR 10
ENV PGBINPATH /usr/lib/postgresql/$PG_MAJOR/bin
ENV PATH $PATH:$PGBINPATH
ENV PGDATA /var/lib/postgresql/data
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

USER root
# Copy Docker basic structure
COPY entrypoint.sh /entrypoint.sh
COPY quickstart-bootstrap.sh /opt/zato/quickstart-bootstrap.sh
COPY supervisord.conf.template /opt/zato/supervisord.conf.template
COPY zato_start_load_balancer /opt/zato/zato_start_load_balancer
COPY zato_start_server1 /opt/zato/zato_start_server1
COPY zato_start_server2 /opt/zato/zato_start_server2
COPY zato_start_web_admin /opt/zato/zato_start_web_admin
COPY zato_start_scheduler /opt/zato/zato_start_scheduler
RUN chmod 755 /entrypoint.sh \
    /opt/zato/quickstart-bootstrap.sh \
    /opt/zato/zato_start_load_balancer \
    /opt/zato/zato_start_server1 \
    /opt/zato/zato_start_server2 \
    /opt/zato/zato_start_web_admin \
    /opt/zato/zato_start_scheduler

EXPOSE 22 6379 8183 17010 17011 11223
CMD [ "/entrypoint.sh" ]
