#!/bin/bash
set -e

PYTHON3_VERSION="3.8.3"
PYTHON3_URL="https://www.python.org/ftp/python/${PYTHON3_VERSION}/Python-${PYTHON3_VERSION}.tgz"
PKGCONFIG_VERSION="0.29.2"
PKGCONFIG_URL="https://pkg-config.freedesktop.org/releases/pkg-config-${PKGCONFIG_VERSION}.tar.gz"
AUTOCONF_VERSION="2.69"
AUTOCONF_URL="https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz"
AUTOMAKE_VERSION="1.16"
AUTOMAKE_URL="https://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.gz"
LIBTOOL_VERSION="2.4.6"
LIBTOOL_URL="http://mirrors.ocf.berkeley.edu/gnu/libtool/libtool-${LIBTOOL_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash

function darwin_python3_install() {
  echo =================== installing ${PYTHON3_URL}
  downloadSource "${PYTHON3_URL}" "${PYTHON3_VERSION}" python3
  makeAndGotoBuildDir darwin python3
	PATH=${TOOLSDIR}/bin:${PATH} ../../src/Python-${PYTHON3_VERSION}/configure \
	  --disable-shared --prefix="$TOOLSDIR"
	make  ${JOBS} install
	cd ../..
	return 0
}


function darwin_pkgconfig_install() {
  echo =================== installing pkgconfig from ${PKGCONFIG_URL}
  downloadSource "${PKGCONFIG_URL}" "${PKGCONFIG_VERSION}" pkgconfig
  makeAndGotoBuildDir darwin pkgconfig
  PKG_CONFIG_LIB_DIR=${TOOLSDIR}/lib/pkgconfig PATH=${TOOLSDIR}/bin:${PATH} \
    ../../src/pkg-config-${PKGCONFIG_VERSION}/configure --prefix=${TOOLSDIR} \
    --disable-shared --with-internal-glib --with-pc-path=${TOOLSDIR}/lib/pkgconfig
  make ${JOBS} install
  cd ../..
  return 0
}


function darwin_autoconf_install() {
  echo =================== installing autoconf from ${AUTOCONF_URL}
  mkdir -p src
  file="autoconf-${AUTOCONF_VERSION}.tar.gz"
  curl -o ./src/${file} "${AUTOCONF_URL}"
	cd src
	tar xzf ${file}
	builddir=../build/darwin-autoconf
	rm -rf ${builddir}
	mkdir -p ${builddir}
	cd ${builddir}
  PATH=${TOOLSDIR}/bin:$PATH ../../src/autoconf-${AUTOCONF_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_automake_install() {
  echo =================== installing automake from ${AUTOMAKE_URL}
  mkdir -p src
  file="automake-${AUTOMAKE_VERSION}.tar.gz"
  curl -o ./src/${file} "${AUTOMAKE_URL}"
	cd src
	tar xzf ${file}
	builddir=../build/darwin-automake
	rm -rf ${builddir}
	mkdir -p ${builddir}
	cd ${builddir}
	mkdir -p ../build/darwin-automake
	cd ../build/darwin-automake
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:$PATH ../../src/automake-${AUTOMAKE_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_libtool_install() {
  echo =================== installing libtool from ${LIBTOOL_URL}
  mkdir -p src
  file="libtool-${LIBTOOL_VERSION}.tar.gz"
  curl -o ./src/${file} "${LIBTOOL_URL}"
	cd src
	tar xzf ${file}
	builddir=../build/darwin-libtool
	rm -rf ${builddir}
	mkdir -p ${builddir}
	cd ${builddir}
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/libtool-${LIBTOOL_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
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
  simpleLib darwin ${PYTHON3_URL} ${PYTHON_VERSION} python3
  darwin_python3_install
  darwin_pkgconfig_install
  darwin_autoconf_install
  darwin_automake_install
  darwin_libtool_install
else
	echo feelings from scratch only works on Darwin right now
fi
