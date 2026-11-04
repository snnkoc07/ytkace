#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
THEOS="${THEOS:-$HOME/theos}"
SDK="${SDK:-$THEOS/sdks/iPhoneOS16.5.sdk}"
if [[ ! -d "$SDK" ]]; then
    SDK="$(xcrun -sdk iphoneos --show-sdk-path)"
fi
TOOLCHAIN="$THEOS/toolchain/linux/iphone/bin"
if [[ ! -x "$TOOLCHAIN/clang" ]] || ! "$TOOLCHAIN/clang" --version >/dev/null 2>&1; then
    TOOLCHAIN="$(dirname "$(xcrun -sdk iphoneos -f clang)")"
fi
VERSION="${FFMPEG_VERSION:-8.1.2}"
MINOS="${FFMPEG_MIN_IOS:-15.0}"
BUILD="$ROOT/.build/ffmpeg"
SOURCE="$BUILD/ffmpeg-$VERSION"
OUTPUT="$ROOT/Vendor/FFmpeg"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu)}"

mkdir -p "$BUILD" "$OUTPUT/lib"
if [[ ! -f "$BUILD/ffmpeg-$VERSION.tar.xz" ]]; then
    curl -L --fail "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz" \
        -o "$BUILD/ffmpeg-$VERSION.tar.xz"
fi
if [[ ! -d "$SOURCE" ]]; then
    tar -xf "$BUILD/ffmpeg-$VERSION.tar.xz" -C "$BUILD"
fi

build_arch() {
    local arch="$1"
    local target="$2"
    local directory="$BUILD/build-$arch"
    local prefix="$BUILD/install-$arch"
    rm -rf "$directory" "$prefix"
    mkdir -p "$directory" "$prefix"
    cd "$directory"
    "$SOURCE/configure" \
        --prefix="$prefix" \
        --target-os=darwin \
        --arch=aarch64 \
        --enable-cross-compile \
        --sysroot="$SDK" \
        --cc="$TOOLCHAIN/clang" \
        --cxx="$TOOLCHAIN/clang++" \
        --ar="$TOOLCHAIN/ar" \
        --ranlib="$TOOLCHAIN/ranlib" \
        --nm="$TOOLCHAIN/nm" \
        --strip="$TOOLCHAIN/strip" \
        --extra-cflags="-target $target -miphoneos-version-min=$MINOS -fPIC -fvisibility=hidden" \
        --extra-cxxflags="-target $target -miphoneos-version-min=$MINOS -fPIC -fvisibility=hidden" \
        --extra-ldflags="-target $target -miphoneos-version-min=$MINOS" \
        --enable-static \
        --disable-shared \
        --enable-pic \
        --enable-small \
        --disable-asm \
        --disable-programs \
        --disable-doc \
        --disable-debug \
        --disable-autodetect \
        --disable-network \
        --disable-everything \
        --enable-avutil \
        --enable-avcodec \
        --enable-avformat \
        --disable-avdevice \
        --disable-avfilter \
        --enable-swscale \
        --disable-swresample \
        --enable-protocol=file \
        --enable-demuxer=mov,matroska,image2 \
        --enable-muxer=mp4 \
        --enable-bsf=aac_adtstoasc \
        --enable-parser=h264,hevc,vp9,av1,aac,mjpeg,png \
        --enable-decoder=h264,hevc,vp9,av1,aac,mjpeg,png \
        --enable-encoder=h264_videotoolbox,hevc_videotoolbox \
        --enable-hwaccel=h264_videotoolbox,hevc_videotoolbox,vp9_videotoolbox,av1_videotoolbox \
        --disable-iconv \
        --disable-zlib \
        --disable-bzlib \
        --disable-lzma \
        --disable-securetransport \
        --enable-videotoolbox \
        --disable-audiotoolbox \
        --disable-avfoundation
    make -j"$JOBS"
    make install
}

build_arch arm64 "arm64-apple-ios$MINOS"

rm -rf "$OUTPUT/include"
cp -R "$BUILD/install-arm64/include" "$OUTPUT/include"
for library in avformat avcodec avutil swscale; do
    cp "$BUILD/install-arm64/lib/lib$library.a" "$OUTPUT/lib/lib$library.a"
done
cp "$SOURCE/COPYING.LGPLv2.1" "$OUTPUT/COPYING.LGPLv2.1"
cp "$SOURCE/COPYING.LGPLv3" "$OUTPUT/COPYING.LGPLv3"
