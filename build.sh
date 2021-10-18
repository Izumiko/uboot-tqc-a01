#!/bin/bash

ATFVER=v2.5
SCPVER=v0.4
UBOOTVER=v2021.10

sudo apt-get update && sudo apt-get install -y bc git build-essential bison flex python3 python3-distutils swig python3-dev libpython3-dev device-tree-compiler wget
wget "https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz"
wget "https://github.com/stffrdhrn/gcc/releases/download/or1k-10.0.0-20190723/or1k-linux-musl-10.0.0-20190723.tar.xz"
tar xf gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz
tar xf or1k-linux-musl-10.0.0-20190723.tar.xz
export PATH=`pwd`/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:`pwd`/or1k-linux-musl/bin:$PATH


wget -O uboot.tar.gz "https://github.com/u-boot/u-boot/archive/refs/tags/${UBOOTVER}.tar.gz"
wget -O atf.tar.gz "https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/${ATFVER}.tar.gz"
wget -O crust.tar.gz "https://github.com/crust-firmware/crust/archive/refs/tags/${SCPVER}.tar.gz"
tar xzf uboot.tar.gz && mv u-boot-*/ u-boot
tar xzf atf.tar.gz && mv arm-trusted-firmware-*/ atf
tar xzf crust.tar.gz && mv crust-*/ crust


echo "Building Arm Trusted Firmware"
cd atf
patch -p1 < ../patches/atf/0001-Fix-reset-issue-on-H6-by-using-R_WDOG.patch
patch -p1 < ../patches/atf/0001-sunxi-Don-t-enable-referenced-regulators.patch
CROSS_COMPILE=aarch64-none-linux-gnu- make PLAT=sun50i_h6 DEBUG=0 bl31 || exit 1
export BL31=`pwd`/build/sun50i_h6/release/bl31.bin

echo "Building SCP firmware"
cd ../crust
sed -i '0,/lex/s//flex/' Makefile
CROSS_COMPILE=or1k-linux-musl- make orangepi_3_defconfig
CROSS_COMPILE=or1k-linux-musl- make scp || exit 1
export SCP=`pwd`/build/scp/scp.bin

echo "Building U-Boot"
cd ../u-boot
patch -p1 < ../patches/u-boot/0020-sunxi-call-fdt_fixup_ethernet-again-to-set-macaddr-f.patch
patch -p1 < ../patches/u-boot/add-tqc-a01.patch
patch -p1 < ../patches/u-boot/enable-autoboot-keyed.patch
patch -p1 < ../patches/u-boot/fdt-setprop-fix-unaligned-access.patch
patch -p1 < ../patches/u-boot/sunxi-boot-splash.patch
CROSS_COMPILE=aarch64-none-linux-gnu- make clean
CROSS_COMPILE=aarch64-none-linux-gnu- make tqc_a01_defconfig
CROSS_COMPILE=aarch64-none-linux-gnu- make || exit 1

cp u-boot-sunxi-with-spl.bin ../
