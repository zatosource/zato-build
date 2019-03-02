# Zato quickstart with Docker



# How to use this image

```console
$ docker build -t zato:3.0 .
$ docker run --name zato-quickstart -d zato:3.0
```

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `docker-compose.yml` for `docker`:

```yaml
version: '3.1'

services:
  zato:
    build: ./
    image: zato:3.0
    restart: on-failure
    environment:
      - ZATO_USER_PASSWORD=mysecretpassword
      - ZATO_WEBADMIN_PASSWORD=mysecretpassword
    ports:
      - 22
      - 6379:6379
      - 8183:8183
      - 17010:17010
      - 17011:17011
      - 11223:11223
```

# How to extend this image

There are many ways to extend the `zato` image. Without trying to support every possible use case, here are just a few that we have found useful.

Example `docker-compose.yml` for `docker` with external Redis and Postgresql:

```yaml
version: '3.1'

services:
  postgres:
    image: 'postgres:alpine'
    restart: on-failure
    environment:
      - POSTGRES_PASSWORD=mysecretpassword
      - POSTGRES_USER=zato
  redis:
    image: redis
    restart: on-failure
  zato:
    build: ./
    image: zato:3.0
    restart: on-failure
    environment:
      - ZATO_USER_PASSWORD=mysecretpassword
      - ZATO_WEBADMIN_PASSWORD=mysecretpassword
      - REDIS_HOSTNAME=redis
      - ODB_TYPE=postgresql
      - ODB_HOSTNAME=postgres
      - ODB_PORT=5432
      - ODB_NAME=zato
      - ODB_USERNAME=zato
      - ODB_PASSWORD=mysecretpassword
    depends_on:
      - redis
      - postgres
    ports:
      - 22
      - 6379:6379
      - 8183:8183
      - 17010:17010
      - 17011:17011
      - 11223:11223
```

## Environment Variables

The Zato image uses several environment variables which are easy to miss. While none of the variables are required, they may significantly aid you in using the image.

### `ZATO_USER_PASSWORD`

This environment variable is recommended for you to use the Zato image. This environment variable sets the password for user `zato` to access through ssh.

If not defined, the value is generated automatically at runtime. You can use this command to retrieve the generated password if needed:

```console
$ docker exec zato:3.0 /bin/bash -c 'cat /opt/zato/zato_user_password'
```

### `ZATO_WEBADMIN_PASSWORD`

This environment variable is recommended for you to use the Zato image. This environment variable sets the password for the web admin’s technical account user to connect with.

If not defined, the value is generated automatically at runtime. You can use this command to retrieve the generated password if needed:

```console
$ docker exec zato:3.0 /bin/bash -c 'cat /opt/zato/web_admin_password'
```

### `REDIS_HOSTNAME`

This environment variable allow you to specify a hostname of an external Redis service or one running in other container. Default value is `localhost`.

If value is  `localhost`, a Redis service will be executed in the Zato's container.

### `ODB_TYPE`

This environment variable sets the ODB type to use. Must be one of: `mysql`, `postgresql` or `sqlite`. Default value is `sqlite`.

### `ODB_HOSTNAME`

If `ODB_TYPE` is not `sqlite`, this environment variable sets the hostname to connect to the ODB service.

### `ODB_PORT`

If `ODB_TYPE` is not `sqlite`, this environment variable sets the port to connect to the ODB service.

### `ODB_NAME`

If `ODB_TYPE` is not `sqlite`, this environment variable sets the name of the database.

### `ODB_USERNAME`

If `ODB_TYPE` is not `sqlite`, this environment variable sets the username used to connect to the ODB service.

### `ODB_PASSWORD`

If `ODB_TYPE` is not `sqlite`, this environment variable sets the password used to connect to the ODB service.
