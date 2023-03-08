#!/usr/bin/env bash

# This mkimage-alpine.bash is a modified version from
# https://github.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash.
# Add some changes due to use s6-overlay "https://github.com/just-containers/s6-overlay".

if [[ ${TARGETARCH}${TARGETVARIANT} == amd64 ]]; then
    declare arch=x86_64
elif [[ ${TARGETARCH}${TARGETVARIANT} == arm64 ]]; then
    declare arch=aarch64
elif [[ ${TARGETARCH}${TARGETVARIANT} == armv7 ]]; then
    declare arch=armv7
elif [[ ${TARGETARCH}${TARGETVARIANT} == armv6 ]]; then
    declare arch=armhf
fi

declare REL="v${ALPINE_VERSION}"
declare MIRROR="${MIRROR:-http://dl-cdn.alpinelinux.org/alpine}"
declare PACKAGES=alpine-baselayout,alpine-keys,apk-tools,busybox,libc-utils,xz

set -eo pipefail; [[ "$TRACE" ]] && set -x

[[ "$(id -u)" -eq 0 ]] || {
	printf >&2 '%s requires root\n' "$0" && exit 1
}

usage() {
	printf >&2 '%s: [-r release] [-m mirror] [-a arch] [-s] [-E] [-e] [-c] [-d] [-t timezone] [-p packages] [-b]\n' "$0" && exit 1
}

build() {
	declare mirror="$1" rel="$2" packages=("${3:-alpine-base}")

	local rootfs
	rootfs="$(mktemp -d "${TMPDIR:-/var/tmp}/alpine-docker-rootfs-XXXXXXXXXX")"

	# conf
	mkdir -p "$rootfs/etc/apk"
	{
		echo "$mirror/$rel/main"
		[[ "$OMIT_COMMUNITY" ]] || echo "$mirror/$rel/community"
		[[ "$REPO_EXTRA" ]] && {
			[[ "$rel" == "edge" ]] || echo "@edge $mirror/edge/main"
			echo "@testing $mirror/edge/testing"
		}
	} > "$rootfs/etc/apk/repositories"

	# mkbase
	{
		# shellcheck disable=SC2086
		apk --root "$rootfs" --update-cache --keys-dir /etc/apk/keys \
			add --arch $arch --initdb ${packages[*]//,/ }
		[[ "$ADD_BASELAYOUT" ]] && \
			apk --root "$rootfs" --keys-dir /etc/apk/keys \
				fetch --stdout --arch $arch alpine-base | tar -xvz -C "$rootfs" etc
		[[ "$TIMEZONE" ]] && {
			apk --root "$rootfs" --keys-dir /etc/apk/keys \
				add --arch $arch -t .timezone tzdata
			cp "$rootfs/usr/share/zoneinfo/$TIMEZONE" "$rootfs/etc/localtime"
			apk --root "$rootfs" --keys-dir /etc/apk/keys \
				del --arch $arch --purge .timezone
		}
		rm -f "$rootfs/var/cache/apk"/*
		[[ "$DISABLE_ROOT_PASSWD" ]] && \
			sed -ie 's/^root::/root:!:/' "$rootfs/etc/shadow"
	} >&2

	[[ "$ADD_APK_SCRIPT" ]] && cp /apk-install "$rootfs/usr/sbin/apk-install"

	# save
	tar -J -f rootfs.tar.xz --numeric-owner --exclude='dev/*' -C "$rootfs" -c .
	[[ "$STDOUT" ]] && cat rootfs.tar.xz

	return 0
}

main() {
	while getopts "hr:m:t:sEecdp:ba:" opt; do
		case $opt in
			r) REL="$OPTARG";;
			m) MIRROR="${OPTARG%/}";;
			s) STDOUT=1;;
			E) OMIT_COMMUNITY=1;;
			e) REPO_EXTRA=1;;
			t) TIMEZONE="$OPTARG";;
			c) ADD_APK_SCRIPT=1;;
			p) PACKAGES="$OPTARG";;
			b) ADD_BASELAYOUT=1;;
			d) DISABLE_ROOT_PASSWD=1;;
			a) ARCH="$OPTARG";;
			*) usage;;
		esac
	done

	build "$MIRROR" "$REL" "$PACKAGES" "$ARCH"
}

main "$@"
