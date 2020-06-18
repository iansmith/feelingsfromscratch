#!/bin/bash
set -e

CMAKE_VERSION="3.17.3"
CMAKE_URL="https://codeload.github.com/Kitware/CMake/tar.gz/v${CMAKE_VERSION}"
EXPAT_URL="git@github.com:libexpat/libexpat.git"
JSONCPP_URL="git@github.com:open-source-parsers/jsoncpp.git"
NINJA_URL="git://github.com/ninja-build/ninja.git"

OS=""
TOOLSDIR=""


function getToolsDir {
 mkdir -p tools
 cd tools
 TOOLSDIR=`pwd`
 cd ..
 return 0
}

function getOS {
	os=`uname -s`
	if [ "$os" == "" ]; then
		echo unable to determine OS, uname -s returned nothing
		exit 1
	fi

	if [ "$os" != "Darwin" ]; then
		echo current feelings from scratch only works on Darwin
		exit 1
	fi
	OS=$os
	return 0
}


function darwin_ninja_install() {
  echo =================== installing ninja from ${NINJA_URL}
  mkdir -p src
  cd src
  rm -rf ninja
  git clone ${NINJA_URL}
  mkdir -p ../build/darwin-ninja
  cd ../build/darwin-ninja
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/ninja/configure.py --bootstrap --platform=darwin --verbose --with-python=$TOOLSDIR/bin/python3
  cp ./ninja ${TOOLSDIR}/bin
  cd ../../
  return 0
}

function darwin_meson_install() {
  echo =================== installing meson from pip3 package

	PATH=${TOOLSDIR}/bin:${PATH} pip3 install --upgrade pip
	PATH=${TOOLSDIR}/bin:${PATH} pip3 install meson
}


function darwin_expat_install() {
  echo =================== installing libexpat from ${EXPAT_URL}
  mkdir -p src
  cd src
  rm -rf expat
  git clone ${EXPAT_URL}
  cd libexpat/expat/
  PATH=${TOOLSDIR}/bin:${PATH} ./buildconf.sh
  cd ../../../
  mkdir -p build/darwin-expat
  cd build/darwin-expat
  #we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/libexpat/expat/configure --prefix=${TOOLSDIR}
  make install
  cd ../..
  return 0
}

function darwin_jsoncpp_install() {
  echo =================== installing libjsoncpp from ${JSONCPP_URL}
  mkdir -p src
  cd src
  rm -rf jsoncpp
  git clone ${JSONCPP_URL}
  mkdir -p ../build/darwin-jsoncpp
  cd ../build/darwin-jsoncpp
  #we have to get meson and ninja
  PATH=${TOOLSDIR}/bin:${PATH} meson  --prefix=${TOOLSDIR} \
  -Ddefault_library=static --pkg-config-path=${TOOLSDIR}/lib/pkgconfig \
  . ../../src/jsoncpp
  PATH=${TOOLSDIR}/bin:${PATH} ninja -C . install
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
	mkdir -p ../build/darwin-cmake
	cd ../build/darwin-cmake
	#PATH=${TOOLSDIR}/bin:$PATH ../../src/CMake-${CMAKE_VERSION}/bootstrap --system-curl --prefix="$TOOLSDIR"
	#make
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
  darwin_expat_install
  darwin_jsoncpp_install
  darwin_expat_install
else
	echo feelings from scratch only works on Darwin right now
fi

echo ----------
echo If everything looks ok, you may want to delete the source code
echo tarballs and the directories derived from them in the src directory.
