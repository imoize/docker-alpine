ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS build-stage

ARG TARGETARCH
ARG TARGETVARIANT
ARG ALPINE_VERSION

ENV REL=v${ALPINE_VERSION}
ENV ROOTFS=/root-out
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils

# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.2.0.2"
ARG S6_OVERLAY_ARCH

# build rootfs and add s6 overlay
RUN \
    apk add --no-cache \
    bash \
    curl \
    xz && \
    if [ ${TARGETARCH}${TARGETVARIANT} == amd64 ]; then ARCH=x86_64; \
    elif [ ${TARGETARCH}${TARGETVARIANT} == arm64 ]; then ARCH=aarch64; fi && \
    if [ -z ${S6_OVERLAY_ARCH+x} ]; then S6_OVERLAY_ARCH=${ARCH}; fi && \
    mkdir -p "$ROOTFS/etc/apk" && \
    { \
        echo "$MIRROR/$REL/main"; \
        echo "$MIRROR/$REL/community"; \
    } > "$ROOTFS/etc/apk/repositories" && \
    apk --root "$ROOTFS" --no-cache --keys-dir /etc/apk/keys add --arch $ARCH --initdb ${PACKAGES//,/ } && \
    sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow && \
    curl -sLO --output-dir /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
    tar -C /root-out -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    curl -sLO --output-dir /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" && \
    tar -C /root-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz && \
    curl -sLO --output-dir /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" && \
    tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    curl -sLO --output-dir /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" && \
    tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

# runtime stage
FROM scratch
COPY --from=build-stage /root-out/ /

ENV PS1="$(whoami)@$(hostname):$(pwd)\\$" \
    HOME="/root" \
    TERM="xterm" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    S6_VERBOSITY="1"

# install packages
RUN \
apk update && apk add --no-cache \
    alpine-release \
    bash \
    ca-certificates \
    coreutils \
    curl \
    jq \
    netcat-openbsd \
    procps-ng \
    shadow \
    tzdata && \
# create user and make folders
    groupmod -g 1000 users && \
    useradd -u 901 -U -d /config -s /bin/false disty && \
    usermod -G users disty && \
    mkdir -p \
    /app \
    /config \
    /defaults && \
# cleanup
    rm -rf \
    /tmp/* \
    /var/cache/apk/*

# add local files
COPY src/ /

ENTRYPOINT ["/init"]