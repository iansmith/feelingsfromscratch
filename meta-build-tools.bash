#!/bin/bash
set -ex

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
AUTOGEN_VERSION="5.18.7"
AUTOGEN_URL="https://ftp.gnu.org/gnu/autogen/autogen-${AUTOGEN_VERSION}.tar.gz"
GUILE_VERSION="2.2.7" #3.0.2
GUILE_URL="https://ftp.gnu.org/gnu/guile/guile-${GUILE_VERSION}.tar.gz"
GC_VERSION="8.0.4"
GC_URL="https://www.hboehm.info/gc/gc_source/gc-${GC_VERSION}.tar.gz"
GSED_VERSION="4.1f"
GSED_URL="ftp://alpha.gnu.org/gnu/sed/sed-${GSED_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash

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
  downloadSource "${AUTOCONF_URL}" "${AUTOCONF_VERSION}" autoconf
  makeAndGotoBuildDir darwin autoconf
  PATH=${TOOLSDIR}/bin:$PATH ../../src/autoconf-${AUTOCONF_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_automake_install() {
  echo =================== installing automake from ${AUTOMAKE_URL}
  downloadSource "${AUTOMAKE_URL}" "${AUTOMAKE_VERSION}" automake
  makeAndGotoBuildDir darwin automake
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:$PATH ../../src/automake-${AUTOMAKE_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_autogen_install() {
  echo =================== installing autogen from ${AUTOGEN_URL}
  downloadSource "${AUTOGEN_URL}" "${AUTOGEN_VERSION}" autogen
  makeAndGotoBuildDir darwin autogen
  cd ../..
  return 0
}

function darwin_libtool_install() {
  echo =================== installing libtool from ${LIBTOOL_URL}
  downloadSource "${LIBTOOL_URL}" "${LIBTOOL_VERSION}" libtool
  makeAndGotoBuildDir darwin libtool
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/libtool-${LIBTOOL_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}
function darwin_guile_install() {
  echo =================== installing guile from ${GUILE_URL}
  downloadSource "${GUILE_URL}" "${GUILE_VERSION}" guile
  makeAndGotoBuildDir darwin guile
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:${PATH} LDFLAGS="-framework CoreFoundation -framework Foundation -framework AppKit" \
    PKG_CONFIG_PATH=${TOOLSDIR}/lib/pkgconfig \
    ../../src/guile-${GUILE_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}
function darwin_autogen_install() {
  echo =================== installing autogen from ${AUTOGEN_URL}
  downloadSource "${AUTOGEN_URL}" "${AUTOGEN_VERSION}" autogen
  makeAndGotoBuildDir darwin autogen
	#we have to get autoconf which we just installed
  PATH=${TOOLSDIR}/bin:${PATH} LDFLAGS="-framework CoreFoundation -framework Foundation -framework AppKit" \
    PKG_CONFIG_PATH=${TOOLSDIR}/lib/pkgconfig \
    ../../src/autogen-${AUTOGEN_VERSION}/configure --prefix=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

##
## START
##

getOS
echo os is ${OS}
if [ "$OS" == "darwin" ]; then
  getToolsDir
  if [ "$?" != "0" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
  standardLib darwin "${PYTHON3_URL}" "${PYTHON3_VERSION}" python3 Python-
  darwin_pkgconfig_install
  darwin_autoconf_install
  darwin_automake_install
  standardLib darwin "${GC_URL}" "${GC_VERSION}" gc
  standardLib darwin "${GSED_URL}" "${GSED_VERSION}" sed
  darwin_libtool_install
  darwin_guile_install
  standardLib darwin "${AUTOGEN_URL}" "${AUTOGEN_VERSION}" autogen
else
	echo feelings from scratch only works on Darwin right now xxx
fi
