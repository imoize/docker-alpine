FROM alpine:3.17.2 AS build-stage

ENV ARCH=x86_64
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils,\
xz

# install packages
RUN \
    apk add --no-cache \
    bash \
    curl \
    patch \
    tar \
    tzdata \
    xz

# fetch builder script from gliderlabs
RUN \
    curl -o \
    /mkimage-alpine.bash -L \
    https://raw.githubusercontent.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash && \
    chmod +x \
    /mkimage-alpine.bash && \
    ./mkimage-alpine.bash && \
    mkdir /build-out && \
    tar xf \
    /rootfs.tar.xz -C \
    /build-out && \
    sed -i -e 's/^root::/root:!:/' //build-out/etc/shadow

# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.4.1"
ARG S6_OVERLAY_ARCH="x86_64"

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /build-out -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C /build-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# runtime stage 
FROM scratch
COPY --from=build-stage /build-out/ /

LABEL maintainer          brilliant
LABEL imoize.github       https://github.com/imoize
LABEL imoize.registry     https://hub.docker.com/u/imoize

ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
    HOME="/root" \
    TERM="xterm" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_VERBOSITY="2"

RUN \
    echo "**** install runtime packages ****" && \
    apk update && apk upgrade && \
    apk add --no-cache \
    alpine-release \
    bash \
    ca-certificates \
    coreutils \
    curl \
    jq \
    procps \
    shadow \
    tzdata && \
    echo "**** create user and make folders ****" && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d /data -s /bin/false disty && \
    usermod -G users disty && \
    mkdir -p \
    /app \
    /config \
    /defaults && \
    echo "**** cleanup ****" && \
    rm -rf \
    /tmp/* \
    /var/cache/apk/*

# add local files
COPY src/ /

ENTRYPOINT ["/init"]