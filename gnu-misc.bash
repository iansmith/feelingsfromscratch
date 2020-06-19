#!/bin/bash
set -e

LIBUNISTRING_VERSION="0.9.10"
LIBUNISTRING_URL="https://ftp.gnu.org/gnu/libunistring/libunistring-${LIBUNISTRING_VERSION}.tar.gz"
FFI_VERSION="3.3"
FFI_URL="https://github.com/libffi/libffi/releases/download/v${FFI_VERSION}/libffi-${FFI_VERSION}.tar.gz"
GETTEXT_VERSION="0.20.2"
GETTEXT_URL="https://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.gz"
PCRE_VERSION="8.44"
PCRE_URL="https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz"
PCRE2_VERSION="10.35"
PCRE2_URL="https://ftp.pcre.org/pub/pcre/pcre2-${PCRE2_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash

function gettextInstall() {
  echo =================== installing gettext from ${GETTEXT_URL}
  downloadSource "${GETTEXT_URL}" "${GETTEXT_VERSION}" gettext
  makeAndGotoBuildDir ${1} gettext
  PATH=${TOOLSDIR}/bin:$PATH ../../src/gettext-${GETTEXT_VERSION}/configure --prefix="$TOOLSDIR"
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_gettext_install() {
  gettext_install darwin
}

function linux_gettext_install() {
  gettextInstall linux
}

function libunistringInstall() {
  echo =================== installing libunistring from ${LIBUNISTRING_URL}
  downloadSource "${LIBUNISTRING_URL}" "${LIBUNISTRING_VERSION}" libunistring
  makeAndGotoBuildDir ${1} libunistring
  PATH=${TOOLSDIR}/bin:$PATH ../../src/libunistring-${LIBUNISTRING_VERSION}/configure --prefix="$TOOLSDIR"
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_libunistring_install() {
  gettext_install darwin
}

function linux_libunistring_install() {
  gettextInstall linux
}

###
### start
###

getOS
if [ "$OS" == "darwin" ]; then
  getToolsDir
  standardLib ${OS} "${FFI_URL}" "${FFI_VERSION}" libffi
  standardLib ${OS} "${LIBUNISTRING_URL}" "${LIBUNISTRING_VERSION}" libunistring

  if [ "$?" != "0" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
else
  if [ "$OS" == "linux" ]; then
    getToolsDir
    apt-get install libffi-dev=${FFI_VERSION}-4
    apt-get install libunistring-dev=${LIBUNISTRING_VERSION}-6
  else
    echo feelings from scratch only works on Darwin right now ${OS}
  fi

  ##comon packages
  standardLib ${OS} "${PCRE_URL}" "${PCRE_VERSION}" pcre
  standardLib ${OS} "${PCRE2_URL}" "${PCRE2_VERSION}" pcre2
  ##different gettext
  if [ "$OS" == "darwin" ]; then
    darwin_gettext_install
  else
    linux_gettext_install
  fi

fi
