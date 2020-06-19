#!/bin/bash
set -ex

BINTOOLS_VERSION="2.34"
BINTOOLS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINTOOLS_VERSION}.tar.gz"


OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash

function darwin_binutils_install() {
  echo =================== installing binutils from ${BINUTILS_URL}
  downloadSource "${BINUTILS_URL}" "${BINUTILS_VERSION}" binutils
  makeAndGotoBuildDir darwin binutils
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/binutils-${BINUTILS_VERSION}/configure \
    --disable-shared --enable-libmpx --with-system-zlib  --with-system-isl \
    --enable-__cxa_atexit -disable-libunwind-exceptions --enable-clocale=gnu \
    --disable-libstdcxx-pch --disable-libssp --enable-plugin \
    --enable-lto --enable-install-libiberty --with-linker-hash-style=gnu \
    --enable-gnu-indirect-function --disable-multilib --disable-werror \
    --enable-checking=release --enable-default-pie \
    --enable-default-ssp --enable-gnu-unique-object enable-ld enable-gold
  make ${JOBS}
  make install
  cd ../..
  return 0
}


##
## START
##

getOS
if [ "$OS" == "Darwin" ]; then
  getToolsDir
  if [ "$?" != "0" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
  darwin_binutils_install
else
	echo feelings from scratch only works on Darwin right now
fi
