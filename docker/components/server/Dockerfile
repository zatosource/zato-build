# Zato server

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
WORKDIR /opt/zato

EXPOSE 17010

RUN mkdir /opt/zato/ca
COPY zato.server.cert.pem /opt/zato/ca/
COPY zato.server.key.pem /opt/zato/ca/
COPY zato.server.key.pub.pem /opt/zato/ca/
COPY ca_cert.pem /opt/zato/ca/
COPY zato_server.config /opt/zato/

RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/docker-zato-components-server/docker/components/server/zato_start_server
RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/docker-zato-components-server/docker/components/server/zato_from_config_create_server
RUN chmod 755 /opt/zato/zato_start_server \
              /opt/zato/zato_from_config_create_server

RUN rm -rf /opt/zato/env/server && mkdir -p /opt/zato/env/server

RUN /opt/zato/zato_from_config_create_server
RUN sed -i 's/gunicorn_workers=2/gunicorn_workers=1/g' \
    /opt/zato/env/server/config/repo/server.conf
RUN sed -i 's/127.0.0.1:17010/0.0.0.0:17010/g' \
    /opt/zato/env/server/config/repo/server.conf

CMD ["/opt/zato/zato_start_server"]
