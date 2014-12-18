# Zato load-balancer

FROM ubuntu:14.04
MAINTAINER Rafał Krysiak <rafal@zato.io>

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y apt-transport-https \
    python-software-properties \
    software-properties-common \
    curl \
    wget

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo to your apt
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/dev/ubuntu
RUN apt-get update && apt-get install -y zato

USER zato

ENV ZATO_BIN /opt/zato/2.0.0/bin/zato
EXPOSE 11223

RUN mkdir /opt/zato/ca
COPY lb.crt.pem /opt/zato/ca/
COPY lb.key.pem /opt/zato/ca/
COPY lb.key.pub.pem /opt/zato/ca/
COPY cacert.pem /opt/zato/ca/

RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/docker-zato-components-lb/docker/components/load-balancer/zato_start_load_balancer
RUN chmod 755 /opt/zato/zato_start_load_balancer

RUN rm -rf /opt/zato/env/load-balancer && mkdir -p /opt/zato/env/load-balancer

RUN $ZATO_BIN create load_balancer /opt/zato/env/load-balancer \
    /opt/zato/ca/lb.key.pub.pem \
    /opt/zato/ca/lb.key.pem \
    /opt/zato/ca/lb.crt.pem \
    /opt/zato/ca/cacert.pem
