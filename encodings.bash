#!/bin/bash
set -e

EXPAT_VERSION="2.2.9"
EXPAT_VERSION_UNDERSCORE="2_2_9"
EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION_UNDERSCORE}/expat-${EXPAT_VERSION}.tar.gz"
ZLIB_VERSION="1.2.11"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
BZIP2_VERSION="1.0.8"
BZIP2_URL="https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz"
XZ_VERSION="5.2.5"
XZ_URL="https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}


source utils.bash

function darwin_expat_install() {
  echo =================== installing libexpat from ${EXPAT_URL}
  downloadSource "${EXPAT_URL}" "${EXPAT_VERSION}" expat
  makeAndGotoBuildDir darwin expat
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/libexpat/expat/configure --disable-shared --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}


function darwin_zlib_install() {
  echo =================== installing zlib from ${ZLIB_URL}
  downloadSource "${ZLIB_URL}" "${ZLIB_VERSION}" zlib
  makeAndGotoBuildDir darwin zlib
  PATH=${TOOLSDIR}/bin:$PATH ../../src/zlib-${ZLIB_VERSION}/configure --static --prefix="$TOOLSDIR"
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_xz_install() {
  echo =================== installing xz from ${XZ_URL}
  downloadSource "${XZ_URL}" "${XZ_VERSION}" xz
  makeAndGotoBuildDir darwin xz
  PATH=${TOOLSDIR}/bin:$PATH ../../src/xz-${XZ_VERSION}/configure --disable-shared --prefix="$TOOLSDIR"
  make ${JOBS} install
  cd ../..
  return 0
}

#must build in tree, it's shell scripts
function darwin_bzip2_install() {
  echo =================== installing bzip2 from ${BZIP2_URL}
  downloadSource "${BZIP2_URL}" "${BZIP2E_VERSION}" libarchive
  cd src/bzip2-${BZIP2_VERSION}
  PATH=${TOOLSDIR}/bin:$PATH make #yes, must be two steps, dont use jobs
  PATH=${TOOLSDIR}/bin:$PATH make install PREFIX="$TOOLSDIR"
  cd ../..
  return 0
}

###
### start
###

getOS
if [ "$OS" == "darwin" ]; then
  getToolsDir
  if [ "$?" != "0" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
  darwin_zlib_install
  standardLib darwin "${XZ_URL}" "${XZ_VERSION}" xz
  standardLib darwin "${EXPAT_URL}" "${EXPAT_VERSION}" expat
  darwin_bzip2_install

else
  echo feelings from scratch only works on Darwin right now
fi
