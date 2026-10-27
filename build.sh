#!/bin/sh

usage()
{
    echo "$0 usage"
    echo "    SDK_VER=xx CROSS_COMPILE=xxx ./build"
    echo "    ex:"
    echo "      CROSS_COMPILE=/host-tools/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- SDK_VER=64bit ./build.sh"
    exit 1
}

if [ "${CROSS_COMPILE}" = "" ]; then
    echo "No CROSS_COMPILE path\n"
    usage
fi

if [ "${SDK_VER}" = "" ]; then
    echo "No SDK_VER\n"
    usage
fi

# Check every library and its public entry header before building RTSP.
check_live555()
{
    for component in liveMedia BasicUsageEnvironment UsageEnvironment groupsock; do
        if [ ! -s "$1/lib/lib${component}.a" ] || [ ! -d "$1/include/$component" ]; then
            echo "Incomplete live555 dependency: $component" >&2
            return 1
        fi
    done
    for header in liveMedia/liveMedia.hh BasicUsageEnvironment/BasicUsageEnvironment.hh \
                  UsageEnvironment/UsageEnvironment.hh groupsock/Groupsock.hh; do
        if [ ! -s "$1/include/$header" ]; then
            echo "Missing live555 header: $header" >&2
            return 1
        fi
    done
}

# Use the explicitly selected installation first.
if [ -n "$LIVE555_DIR" ]; then
    check_live555 "$LIVE555_DIR" || exit 1
    LIVE555_DIR=$(CDPATH= cd -- "$LIVE555_DIR" && pwd) || exit 1
else
    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
    sdk_root=${TOP_DIR:-$(dirname "$script_dir")}
    live555_tar=

    # Prefer the dependency package shipped with this SDK.
    if [ -f "$sdk_root/oss/oss_release_tarball/$SDK_VER/live555.tar.gz" ]; then
        live555_tar="$sdk_root/oss/oss_release_tarball/$SDK_VER/live555.tar.gz"
    # Reuse the package prepared by build_3rd_party.
    elif [ -n "$OSS_TARBALL_PATH" ] && [ -f "$OSS_TARBALL_PATH/live555.tar.gz" ]; then
        live555_tar="$OSS_TARBALL_PATH/live555.tar.gz"
    # Keep compatibility with the existing prebuilt package.
    elif [ -f prebuilt/live555.tar.gz ]; then
        live555_tar=prebuilt/live555.tar.gz
    # Require complete environment settings for the internal download fallback.
    elif [ -z "$FTP_SERVER_IP" ] || [ -z "$FTP_SERVER_NAME" ] || [ -z "$FTP_SERVER_PWD" ]; then
        echo "No live555 package. Set LIVE555_DIR or prepare the SDK dependency package." >&2
        exit 1
    fi

    mkdir -p prebuilt || exit 1
    live555_tmp=$(mktemp -d prebuilt/.live555.XXXXXX) || exit 1
    trap 'rm -rf "$live555_tmp"' 0
    trap 'exit 1' 1 2 15

    if [ -n "$live555_tar" ]; then
        cp "$live555_tar" "$live555_tmp/live555.tar.gz" || exit 1
    else
        # Internal downloads require credentials supplied by the build environment.
        curl --fail --silent --show-error --connect-timeout 10 \
            --user "$FTP_SERVER_NAME:$FTP_SERVER_PWD" \
            "ftp://$FTP_SERVER_IP/sw_rls/third_party/latest/$SDK_VER/live555.tar.gz" \
            --output "$live555_tmp/live555.tar.gz" || exit 1
    fi

    # Validate a fresh extraction so stale files cannot hide an incomplete package.
    mkdir "$live555_tmp/root" || exit 1
    tar -xzf "$live555_tmp/live555.tar.gz" -C "$live555_tmp/root" || exit 1
    check_live555 "$live555_tmp/root" || exit 1
    # Keep the installed dependency layout used by SDK consumers.
    for live555_component in include lib bin; do
        if [ -d "$live555_tmp/root/$live555_component" ]; then
            rm -rf "prebuilt/$live555_component" || exit 1
            mv "$live555_tmp/root/$live555_component" "prebuilt/$live555_component" || exit 1
        fi
    done
    mv "$live555_tmp/live555.tar.gz" prebuilt/live555.tar.gz || exit 1
    LIVE555_DIR="$(pwd)/prebuilt"
fi

CC=${CROSS_COMPILE}gcc
CXX=${CROSS_COMPILE}g++
AR=${CROSS_COMPILE}ar
RANLIB=${CROSS_COMPILE}ranlib

make clean || exit 1
make CC="${CC}" CXX="${CXX}" AR="${AR}" RANLIB="${RANLIB}" \
    LIVE555_DIR="${LIVE555_DIR}" MW_DIR="${MW_DIR}"
test $? -ne 0 && echo "build cvi rtsp fail!!!" && exit 1
exit 0
