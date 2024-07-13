#!/bin/bash

ATFVER=lts-v2.10.4
SCPVER=v0.6
UBOOTVER=v2024.07

sudo apt-get update && sudo apt-get install -y bc git build-essential bison flex python3 python3-distutils swig python3-dev libpython3-dev device-tree-compiler wget
wget "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
wget "https://github.com/openrisc/or1k-gcc/releases/download/or1k-12.0.1-20220210-20220304/or1k-linux-12.0.1-20220210-20220304.tar.xz"
tar xf arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
tar xf or1k-linux-12.0.1-20220210-20220304.tar.xz
export PATH=`pwd`/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin:`pwd`/or1k-linux/bin:$PATH


wget -O uboot.tar.gz "https://github.com/u-boot/u-boot/archive/refs/tags/${UBOOTVER}.tar.gz"
wget -O atf.tar.gz "https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/${ATFVER}.tar.gz"
wget -O crust.tar.gz "https://github.com/crust-firmware/crust/archive/refs/tags/${SCPVER}.tar.gz"
tar xzf uboot.tar.gz && mv u-boot-*/ u-boot
tar xzf atf.tar.gz && mv arm-trusted-firmware-*/ atf
tar xzf crust.tar.gz && mv crust-*/ crust


echo "Building Arm Trusted Firmware"
cd atf
for f in `ls ../patches/atf/`
do
  patch -p1 < ../patches/atf/$f || exit 1
done
CROSS_COMPILE=aarch64-none-linux-gnu- make PLAT=sun50i_h6 DEBUG=0 bl31 || exit 1
export BL31=`pwd`/build/sun50i_h6/release/bl31.bin

echo "Building SCP firmware"
cd ../crust
sed -i '0,/lex/s//flex/' Makefile
CROSS_COMPILE=or1k-linux- make orangepi_3_defconfig
CROSS_COMPILE=or1k-linux- make scp || exit 1
export SCP=`pwd`/build/scp/scp.bin

echo "Building U-Boot"
cd ../u-boot
for f in `ls ../patches/u-boot/`
do
  patch -p1 < ../patches/u-boot/$f || exit 1
done
CROSS_COMPILE=aarch64-none-linux-gnu- make clean
CROSS_COMPILE=aarch64-none-linux-gnu- make tqc_a01_defconfig
CROSS_COMPILE=aarch64-none-linux-gnu- make || exit 1

cp u-boot-sunxi-with-spl.bin ../
