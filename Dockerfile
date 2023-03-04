FROM alpine:3.17 as build-stage

ARG TARGETARCH
ARG TARGETVARIANT
ARG REL_VERSION="v3.17"

# add required packages
RUN \
    apk add --no-cache \
    bash \
    curl \
    patch \
    tar \
    tzdata \
    xz

# fetch builder script
COPY scripts/mkimage-alpine.bash /
RUN \
    ./mkimage-alpine.bash && \
    mkdir /build-out && \
    tar xf \
    /rootfs.tar.xz -C \
    /build-out && \
    sed -i -e 's/^root::/root:!:/' //build-out/etc/shadow

# build images per arch 
FROM build-stage AS base-amd64
ARG S6_OVERLAY_ARCH="x86_64"

FROM build-stage AS base-arm64
ARG S6_OVERLAY_ARCH="aarch64"

FROM build-stage AS base-armv7
ARG S6_OVERLAY_ARCH="armhf"

FROM build-stage AS base-armv6
ARG S6_OVERLAY_ARCH="arm"

# s6-stage
FROM base-${TARGETARCH}${TARGETVARIANT} as s6-stage

# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.4.1"

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /build-out -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C /build-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# runtime stage
FROM scratch
COPY --from=s6-stage /build-out/ /

ARG PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
    HOME="/root" \
    TERM="xterm"
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
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
    useradd -u 911 -U -d /config -s /bin/false disty && \
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