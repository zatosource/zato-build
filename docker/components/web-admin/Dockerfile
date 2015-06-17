# Zato web-admin

FROM ubuntu:14.04
MAINTAINER Rafał Krysiak <rafal@zato.io>

RUN ln -s -f /bin/true /usr/bin/chfn

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y apt-transport-https \
    python-software-properties \
    software-properties-common \
    curl \
    telnet \
    wget

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo to your apt
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
RUN apt-get update && apt-get install -y zato

COPY zato_update_password.config /opt/zato/
RUN chmod 755 /opt/zato/zato_update_password.config
RUN chown zato:zato /opt/zato/zato_update_password.config

USER zato

EXPOSE 8183

# Prepare additional config files, CA certificates, keys and starter scripts
RUN mkdir /opt/zato/ca
COPY zato.web_admin.cert.pem /opt/zato/ca/
COPY zato.web_admin.key.pem /opt/zato/ca/
COPY zato.web_admin.key.pub.pem /opt/zato/ca/
COPY ca_cert.pem /opt/zato/ca/
COPY zato_web_admin.config /opt/zato/

RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/master/docker/components/web-admin/zato_start_web_admin
RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/master/docker/components/web-admin/zato_from_config_create_web_admin
RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/master/docker/components/web-admin/zato_from_config_update_password

RUN chmod 755 /opt/zato/zato_start_web_admin /opt/zato/zato_from_config_create_web_admin \
              /opt/zato/zato_from_config_update_password

RUN rm -rf /opt/zato/env/web-admin && mkdir -p /opt/zato/env/web-admin

# Set a password for an user and append it to a config file
WORKDIR /opt/zato
RUN touch /opt/zato/web_admin_password
RUN uuidgen > /opt/zato/web_admin_password
WORKDIR /opt/zato
RUN echo 'password'=$(cat /opt/zato/web_admin_password) >> /opt/zato/zato_update_password.config

WORKDIR /opt/zato
RUN /opt/zato/zato_from_config_create_web_admin
RUN /opt/zato/zato_from_config_update_password
RUN sed -i 's/127.0.0.1/0.0.0.0/g' \
    /opt/zato/env/web-admin/config/repo/web-admin.conf

CMD ["/opt/zato/zato_start_web_admin"]
