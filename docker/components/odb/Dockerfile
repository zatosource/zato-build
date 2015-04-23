# Zato ODB & Cluster

FROM ubuntu:14.04
MAINTAINER Andrzej Wróbel <andy@zato.io>

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

USER zato
WORKDIR /opt/zato

COPY zato_odb.config /opt/zato/
COPY zato_cluster.config /opt/zato/

RUN wget -P /opt/zato \
     https://raw.githubusercontent.com/andy-wr/zato-docker/master/odb_cluster/zato_from_config_create_odb
RUN wget -P /opt/zato \
     https://raw.githubusercontent.com/andy-wr/zato-docker/master/odb_cluster/zato_from_config_create_cluster

RUN chmod 755 /opt/zato/zato_from_config_create_odb /opt/zato/zato_from_config_create_cluster

RUN /opt/zato/zato_from_config_create_odb
RUN /opt/zato/zato_from_config_create_cluster
