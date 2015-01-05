# Zato web-admin

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

EXPOSE 8183

RUN mkdir /opt/zato/ca
COPY zato.webadmin.cert.pem /opt/zato/ca/
COPY zato.webadmin.key.pem /opt/zato/ca/
COPY zato.webadmin.key.pub.pem /opt/zato/ca/
COPY ca_cert.pem /opt/zato/ca/
COPY get_zato_version.sh /opt/zato/
COPY zato_web_admin.config /opt/zato/

RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/docker-zato-components-web-admin/docker/components/web-admin/zato_start_web_admin
RUN chmod 755 /opt/zato/zato_start_web_admin

RUN rm -rf /opt/zato/env/web-admin && mkdir -p /opt/zato/env/web-admin

WORKDIR /opt/zato
RUN ./get_zato_version.sh

ENTRYPOINT ["/opt/zato/zato_start_web_admin"]
