#!/bin/bash
set -ex

CMAKE_VERSION="3.17.3"
CMAKE_URL="https://codeload.github.com/Kitware/CMake/tar.gz/v${CMAKE_VERSION}"
NINJA_URL="git://github.com/ninja-build/ninja.git"
LIBARCHIVE_VERSION="3.4.3"
LIBARCHIVE_URL="https://www.libarchive.org/downloads/libarchive-${LIBARCHIVE_VERSION}.tar.gz"
LIBRHASH_VERSION="1.3.9"
LIBRHASH_URL="https://github.com/rhash/RHash/archive/v${LIBRHASH_VERSION}.tar.gz"
LIBUV_VERSION="1.38.0"
LIBUV_URL="https://github.com/libuv/libuv/archive/v${LIBUV_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash


function darwin_ninja_install() {
  echo =================== installing ninja from ${NINJA_URL}
  mkdir -p src
  cd src
  rm -rf ninja
  git clone ${NINJA_URL}
  builddir=../build/darwin-ninja
	rm -rf ${builddir}
	mkdir -p ${builddir}
	cd ${builddir}
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/ninja/configure.py --bootstrap \
    --platform=darwin --verbose --with-python=$TOOLSDIR/bin/python3
  cp ./ninja ${TOOLSDIR}/bin
  cd ../../
  return 0
}

function darwin_meson_install() {
  echo =================== installing meson from pip3 package

	PATH=${TOOLSDIR}/bin:${PATH} pip3 install --upgrade pip
	PATH=${TOOLSDIR}/bin:${PATH} pip3 install meson
}


# no out of tree build?  ARRRGH
function darwin_librhash_install() {
  echo =================== installing librhash from ${LIBRHASH_URL}
  downloadSource "${LIBRHASH_URL}" "${LIBRHASH_VERSION}" librhash
  altname="RHash-${LIBRHASH_VERSION}"
  cd src/${altname}
	PATH=${TOOLSDIR}/bin:$PATH ./configure --disable-lib-shared \
	  --enable-lib-static --enable-static --prefix="$TOOLSDIR" --enable-openssl \
	  --extra-ldflags="-L${TOOLSDIR}/lib" --extra-cflags="-I${TOOLSDIR}/include"
	make ${JOBS}
	make ${JOBS} install
	cd ../..
	return 0
}

function darwin_libuv_install() {
  echo =================== installing libuv from ${LIBUV_URL}
  downloadSource "${LIBUV_URL}" "${LIBUV_VERSION}" libuv
  cd src/libuv-${LIBUV_VERSION}
  LIBTOOLIZE=libtoolize PATH=${TOOLSDIR}/bin:$PATH ./autogen.sh
  cd ../..
  makeAndGotoBuildDir darwin nettle
	PATH=${TOOLSDIR}/bin:$PATH ../../src/libuv-${LIBUV_VERSION}/configure \
	  --disable-shared --prefix="$TOOLSDIR"
	make ${JOBS}
	make ${JOBS} install
	cd ../..
	return 0
}


function darwin_cmake_install() {
  echo =================== installing cmake from ${CMAKE_URL}
  mkdir -p src
  file="cmake-${CMAKE_VERSION}src.tar.gz"
	curl -o ./src/${file} "${CMAKE_URL}"
	cd src
	tar xzf ${file}
	builddir=../build/darwin-cmake
	rm -rf ${builddir}
	mkdir -p ${builddir}
	cd ${builddir}
	PATH=${TOOLSDIR}/bin:$PATH ../../src/CMake-${CMAKE_VERSION}/bootstrap \
	  --system-libs --system-curl --prefix="$TOOLSDIR"
	make ${JOBS} install
	cd ../..
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
  darwin_meson_install
  darwin_ninja_install
  standardLib darwin "${LIBARCHIVE_URL}" "${LIBARCHIVE_VERSION}" libarchive
  darwin_librhash_install
  darwin_libuv_install
  darwin_cmake_install
else
	echo feelings from scratch only works on Darwin right now
fi
