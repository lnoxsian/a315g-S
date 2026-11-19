#!/bin/bash
set -e

# Detect Toolchain
if [ -d "$(pwd)/toolchain/bin" ]; then
    TC_DIR="$(pwd)/toolchain"
elif [ -d "$(pwd)/../toolchain/bin" ]; then
    TC_DIR="$(pwd)/../toolchain"
elif [ -n "$TOOLCHAIN_DIR" ]; then
    TC_DIR="$TOOLCHAIN_DIR"
else
    echo "ERROR: Proton-clang toolchain not found!"
    echo "Please clone it: git clone --depth=1 https://github.com/kdrag0n/proton-clang.git toolchain"
    exit 1
fi

export PATH="${TC_DIR}/bin:$PATH"

export CC="clang"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=r

export KCFLAGS="-w"
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

DEFCONFIG="${1:-a31_recovery_defconfig}"
OUT_DIR="$(pwd)/out"

echo "=========================================="
echo " Building Slim Recovery Kernel for A31"
echo " Defconfig: $DEFCONFIG"
echo " Toolchain: $TC_DIR"
echo "=========================================="

mkdir -p "$OUT_DIR"

echo "==> Configuring $DEFCONFIG..."
make -C $(pwd) O="$OUT_DIR" ARCH=arm64 CC="$CC" CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" CLANG_TRIPLE="$CLANG_TRIPLE" "$DEFCONFIG"

echo "==> Compiling kernel and DTBs..."
make -C $(pwd) O="$OUT_DIR" ARCH=arm64 CC="$CC" CROSS_COMPILE="$CROSS_COMPILE" CROSS_COMPILE_ARM32="$CROSS_COMPILE_ARM32" CLANG_TRIPLE="$CLANG_TRIPLE" -j$(nproc) Image dtbs

echo "==> Generating compressed Image.gz..."
gzip -9 -c "$OUT_DIR/arch/arm64/boot/Image" > "$OUT_DIR/arch/arm64/boot/Image.gz"

echo "=========================================="
echo " BUILD COMPLETE!"
echo " Raw Image: $(ls -lh $OUT_DIR/arch/arm64/boot/Image | awk '{print $5}')"
echo " Slim Gzip: $(ls -lh $OUT_DIR/arch/arm64/boot/Image.gz | awk '{print $5}')"
echo "=========================================="
