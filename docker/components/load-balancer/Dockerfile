# Zato load-balancer

FROM rafal/zato-2.0.0pre1
MAINTAINER Rafał Krysiak <rafal@zato.io>

USER zato

EXPOSE 11223

RUN mkdir -p /opt/zato/env/load-balancer

RUN wget -P /opt/zato \
    https://raw.githubusercontent.com/zatosource/zato-build/docker-zato-components-lb/docker/components/load-balancer/zato_start_load_balancer
RUN chmod 755 /opt/zato/zato_start_load_balancer
