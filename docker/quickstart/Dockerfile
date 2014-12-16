# Zato

FROM ubuntu:14.04
MAINTAINER Rafał Krysiak <rafal@zato.io>

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y apt-transport-https \
    python-software-properties \
    software-properties-common \
    curl \
    redis-server \
    supervisor

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo to your apt
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/dev/ubuntu
RUN apt-get update && apt-get install -y zato

# Setup supervisor
RUN mkdir -p /var/log/supervisor
# Create work environment for Zato 2.0.0

# Switch to zato user and create Zato environment
USER zato

# Expose ports
EXPOSE 6379 8183 17010 17011 11223

WORKDIR /opt/zato
RUN mkdir -p /opt/zato/zato_start_wrapper_scripts

COPY supervisord.conf /opt/zato/
COPY update_password.config /opt/zato/
COPY zato_start_load_balancer /opt/zato/zato_start_wrapper_scripts/
COPY zato_start_server1 /opt/zato/zato_start_wrapper_scripts/
COPY zato_start_web_admin /opt/zato/zato_start_wrapper_scripts/

# Set a password for an user and append it to a config file
RUN touch /opt/zato/web_admin_password
RUN uuidgen > /opt/zato/web_admin_password
RUN echo 'password'=$(cat /opt/zato/web_admin_password) >> /opt/zato/update_password.config

ENV ZATO_BIN /opt/zato/2.0.0/bin/zato

RUN mkdir -p /opt/zato/env/qs-1
RUN rm -rf /opt/zato/env/qs-1 && mkdir -p /opt/zato/env/qs-1

WORKDIR /opt/zato/env/qs-1
RUN $ZATO_BIN quickstart create . sqlite localhost 6379 --verbose --kvdb_password ""
RUN $ZATO_BIN from-config /opt/zato/update_password.config
RUN sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/qs-1/load-balancer/config/repo/zato.config

USER root
CMD /usr/bin/supervisord -c /opt/zato/supervisord.conf
