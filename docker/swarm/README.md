# Run Zato in a local Docker Swarm

## Start a local Docker Swarm

- Start a Virtual Machine
```
$ docker-machine create default
```
- Initialize Docker Swarm
```
docker swarm init --advertise-addr $(docker-machine ip default)
```
- Set up the environment for the Docker client to access the Docker Swarm
```
eval $(docker-machine env default default)
```

## Deploy Zato to Docker Swarm

- Set up the environment for the Docker client to access the Docker Swarm
```
eval $(docker-machine env default default)
```
- Install [Dockerize](https://github.com/powerman/dockerize#installation). It will be used to create the docker-compose.yml.
- Edit the file **environment**.
- Generate the docker-compose.yml with your values from **environment** and the ip address of the Virtual Machine.
```
IP_ADDRESS=$(docker-machine ip) dockerize -env environment -template docker-compose.yml.template:docker-compose.yml
```
- Deploy Zato in to Docker Swarm
```
docker stack deploy -c docker-compose.yml zato
```
- Check if the deploy was make
```
$ docker ps -a
CONTAINER ID        IMAGE                                                           COMMAND                  CREATED             STATUS              PORTS                                  NAMES
4d244a554e1f        registry.gitlab.com/zatosource/zato-core/cloud/testing:latest   "/tini -- /entrypoin…"   43 minutes ago      Up 43 minutes       8183/tcp, 11223/tcp, 17010-17011/tcp   zato_zato_scheduler.1.vur79awtjgx7xslna8nqv8h35
f73671b2647f        redis:latest                                                    "docker-entrypoint.s…"   43 minutes ago      Up 43 minutes       6379/tcp                               zato_redis.1.10b925av9sg41yqa6mwg1j4rn
3e0fdb1b680f        postgres:alpine                                                 "docker-entrypoint.s…"   43 minutes ago      Up 43 minutes       5432/tcp                               zato_postgres.1.ul2amhsdwm9vudht362xiwtq5
702c39abddfd        adminer:standalone                                              "entrypoint.sh docke…"   43 minutes ago      Up 43 minutes       8080/tcp                               zato_adminerzato.1.qwireqafwch4dvplkhb4xy3k6
f8a764c876df        traefik:latest                                                  "/traefik -l DEBUG -…"   43 minutes ago      Up 43 minutes       80/tcp                                 zato_zato_lb.1.7q0emd1o15zgxfq1ji6zrcra1
812b64124c09        registry.gitlab.com/zatosource/zato-core/cloud/testing:latest   "/tini -- /entrypoin…"   43 minutes ago      Up 43 minutes       8183/tcp, 11223/tcp, 17010-17011/tcp   zato_zato_webadmin.1.kl0l2vlslpwiutsjopcxa9t1t
3cde07e68f22        registry.gitlab.com/zatosource/zato-core/cloud/testing:latest   "/tini -- /entrypoin…"   43 minutes ago      Up 43 minutes       8183/tcp, 11223/tcp, 17010-17011/tcp   zato_zato_server.1.c21pmddnwlh0vh0wt8ap6cw8j
bb4e876b4f0b        registry.gitlab.com/zatosource/zato-core/cloud/testing:latest   "/tini -- /entrypoin…"   43 minutes ago      Up 43 minutes       8183/tcp, 11223/tcp, 17010-17011/tcp   zato_zato_server.2.xed16xovjicuxcuynk36pkb7b
b7bd81477dd8        registry.gitlab.com/zatosource/zato-core/cloud/testing:latest   "/tini -- /entrypoin…"   43 minutes ago      Up 43 minutes       8183/tcp, 11223/tcp, 17010-17011/tcp   zato_zato_bootstrap.1.sqo8n8olowij4ijc18bs8qsrw
```

## Next steps

- Set up the environment for the Docker client to access the Docker Swarm
```
eval $(docker-machine env default default)
```
- Check log of Zato server 1 (the Zato Server container name will be different)
```
$ docker logs -f zato_zato_server.1.c21pmddnwlh0vh0wt8ap6cw8j
```
- Check access to Zato servers
```
$ curl http://api.$(docker-machine ip default).nip.io/zato/ping
{"zato_env": {"details": "", "result": "ZATO_OK", "cid": "93bf40452dc0cc2a9d548614"}, "zato_ping_response": {"pong": "zato"}}
```
- Get Zato's Web Admin interface URL
```
$ echo http://webadmin.$(docker-machine ip default).nip.io
```
