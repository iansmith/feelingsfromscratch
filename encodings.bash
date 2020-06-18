#!/bin/bash
set -ex

EXPAT_VERSION="2.2.9"
EXPAT_VERSION_UNDERSCORE="2_2_9"
EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION_UNDERSCORES}/expat-${EXPAT_VERSION}.tar.gz"
JSONCPP_VERSION="1.9.3"
JSONCPP_URL="https://github.com/open-source-parsers/jsoncpp/archive/${JSONCPP_VERSION}.tar.gz"
ZLIB_VERSION="1.2.11"
ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
BZIP2_VERSION="1.0.8"
BZIP2_URL="https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz"
XZ_VERSION="5.2.5"
XZ_URL="https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz"

OS=""
TOOLSDIR=""

source utils.bash

function darwin_expat_install() {
  echo =================== installing libexpat from ${EXPAT_URL}
  downloadSource "${EXPAT_URL}" "${EXPAT_VERSION}" expat
  makeAndGotoBuildDir darwin expat
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/libexpat/expat/configure --disable-shared --prefix=${TOOLSDIR}
  make install
  cd ../..
  return 0
}

function darwin_jsoncpp_install() {
  echo =================== installing libjsoncpp from ${JSONCPP_URL}
  downloadSource "${JSONCPP_URL}" "${JSONCPP_VERSION}" jsoncpp
  makeAndGotoBuildDir darwin jsoncpp
  PATH=${TOOLSDIR}/bin:$PATH meson --prefix="$TOOLSDIR" \
    -Ddefault_library=static . ../../src/jsoncpp-${JSONCPP_VERSION}
  PATH=${TOOLSDIR}/bin:$PATH ninja -C . install
  cd ../..
  return 0
}

function darwin_zlib_install() {
  echo =================== installing zlib from ${ZLIB_URL}
  downloadSource "${ZLIB_URL}" "${ZLIB_VERSION}" zlib
  makeAndGotoBuildDir darwin zlib
  #  mkdir -p src
  #  file="zlib-${ZLIB_VERSION}src.tar.gz"
  #	curl -o ./src/${file} "${ZLIB_URL}"
  #	cd src
  #	tar xzf ${file}
  #	builddir=../build/darwin-zlib
  #	rm -rf ${builddir}
  #	mkdir -p ${builddir}
  #	cd ${builddir}
  PATH=${TOOLSDIR}/bin:$PATH ../../src/zlib-${ZLIB_VERSION}/configure --static --prefix="$TOOLSDIR"
  make install
  cd ../..
  return 0
}

function darwin_xz_install() {
  echo =================== installing xz from ${XZ_URL}
  downloadSource "${XZ_URL}" "${XZ_VERSION}" xz
  makeAndGotoBuildDir darwin xz

  #  mkdir -p src
  #  file="xz-${XZ_VERSION}src.tar.gz"
  #	curl -L -o ./src/${file} "${XZ_URL}"
  #	cd src
  #	tar xzf ${file}
  #	builddir=../build/darwin-xz
  #	rm -rf ${builddir}
  #	mkdir -p ${builddir}
  #	cd ${builddir}
  PATH=${TOOLSDIR}/bin:$PATH ../../src/xz-${XZ_VERSION}/configure --disable-shared --prefix="$TOOLSDIR"
  make install
  cd ../..
  return 0
}

#must build in tree, it's shell scripts
function darwin_bzip2_install() {
  echo =================== installing bzip2 from ${BZIP2_URL}
  downloadSource "${LIBARCHIVE_URL}" "${LIBARCHIVE_VERSION}" libarchive
  #  mkdir -p src
  #  file="bzip2-${BZIP2_VERSION}src.tar.gz"
  #	curl -o ./src/${file} "${BZIP2_URL}"
  #	cd src
  #	tar xzf ${file}
  cd src/bzip2-${BZIP2_VERSION}
  PATH=${TOOLSDIR}/bin:$PATH make #yes, must be two steps
  PATH=${TOOLSDIR}/bin:$PATH make install PREFIX="$TOOLSDIR"
  cd ../..
  return 0
}

###
### start
###

getOS
if [ "$OS" == "Darwin" ]; then
  getToolsDir
  if [ "$?" != "0" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
  standardLib darwin "${ZLIB_URL}" "${ZLIB_VERSION}" zlib
  standardLib darwin "${XZ_URL}" "${XZ_VERSION}" xz
  standardLib darwin "${EXPAT_URL}" "${EXPAT_VERSION}" expat
  darwin_bzip2_install
  darwin_jsoncpp_install

else
  echo feelings from scratch only works on Darwin right now
fi

echo ----------
echo If everything looks ok, you may want to delete the source code
echo tarballs and the directories derived from them in the src directory.
