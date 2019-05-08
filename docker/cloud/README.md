# Zato's Docker image for cloud

## How to build and upload this image

```console
$ docker login registry.gitlab.com
$ docker build -t registry.gitlab.com/zatosource/docker-registry/cloud:3.1 .
$ docker push registry.gitlab.com/zatosource/docker-registry/cloud:3.1
```

## How to update the tag "latest" to point to this image

```console
$ docker tag registry.gitlab.com/zatosource/docker-registry/cloud:3.1 registry.gitlab.com/zatosource/docker-registry/cloud:latest
$ docker push registry.gitlab.com/zatosource/docker-registry/cloud:latest
```
