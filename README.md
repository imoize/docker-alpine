# Alpine-s6 Docker Image

Custom image based on alpine with s6-overlay. 

[![Github Build Status](https://img.shields.io/github/actions/workflow/status/imoize/docker-base-alpine/build-prod-ci.yml?color=458837&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=build&logo=github)](https://github.com/imoize/docker-base-alpine/actions?workflow=build-prod-ci)
[![GitHub](https://img.shields.io/static/v1.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=imoize&message=GitHub&logo=github)](https://github.com/imoize/docker-base-alpine)
[![GitHub Package Repository](https://img.shields.io/static/v1.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=imoize&message=GitHub%20Package&logo=github)](https://github.com/imoize/docker-base-alpine/pkgs/container/alpine-s6)
[![Docker Pulls](https://img.shields.io/docker/pulls/imoize/alpine-s6.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=pulls&logo=docker)](https://hub.docker.com/r/imoize/alpine-s6)

## Supported Architectures

We utilise the docker manifest for multi-platform awareness. More information is available from docker [here](https://github.com/docker/distribution/blob/master/docs/spec/manifest-v2-2.md#manifest-list).

Simply pulling using `latest` tag should retrieve the correct image for your arch.

The architectures supported by this image:

| Architecture | Available |
| :----: | :----: |
| x86-64 | ✅ |
| arm64 | ✅ |
| armv7 | ✅ |
| armv6 | ✅ |

## Usage

Here are some example to help you get started creating a container, easiest way to setup is using docker-compose or use docker cli.

#### docker-compose (recommended)

```yaml
---
version: "3.9"
services:
  alpine:
    image: imoize/alpine-s6:latest
    container_name: alpine
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Asia/Jakarta
    restart: always
```

#### docker cli

```bash
docker run -d \
  --name=alpine \
  -e PUID=1001 \
  -e PGID=1001 \
  -e TZ=Asia/Jakarta \
  --restart always \
  imoize/alpine-s6:latest
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above).

| Parameter | Function |
| :---: | --- |
| PUID | for UserID |
| PGID | for GroupID |
| TZ | specify a timezone see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). |

## User / Group Identifiers

For example: `PUID=1001` and `PGID=1001`, to find yours user `id` and `gid` type `id <your_username>` in terminal.
```bash
  $ id your_username
    uid=1001(user) gid=1001(group) groups=1001(group)
```

## Tips Info

* Shell access whilst the container is running:
```console
docker exec -it alpine /bin/bash
```
* To monitor the logs of the container in realtime:
```console
docker logs -f alpine
```
* Container version number:
```console
docker inspect -f '{{ index .Config.Labels "build_version" }}' alpine
```
* Image version number:
```console
docker inspect -f '{{ index .Config.Labels "build_version" }}' imoize/alpine-s6:latest
```

## Upgrade this image

We recommend that you follow these steps to upgrade your container.

#### Step 1: Get the updated image

```console
docker pull imoize/alpine-s6:latest
```

or if you're using Docker Compose, update the value of the image property to
`imoize/alpine-s6:latest`.

#### Step 2: Stop currently running container

Stop the currently running container using this command.

```console
docker stop alpine
```

or using Docker Compose:

```console
docker-compose stop alpine
```

#### Step 3: Remove currently running container

Remove the currently running container using this command.

```console
docker rm -v alpine
```

or using Docker Compose:

```console
docker-compose rm -v alpine
```

#### Step 4: Run the new image

Re-create your container from the new image.

```console
docker run --name alpine imoize/alpine-s6:latest
```

or using Docker Compose:

```console
docker-compose up -d alpine
```

#### Step 5: Remove the old dangling images

You can also remove the old dangling images.

```console
docker image prune
```

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/imoize/docker-base-alpine/issues) or submitting a [pull request](https://github.com/imoize/docker-base-alpine/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can create an [issue](https://github.com/imoize/docker-base-alpine/issues).