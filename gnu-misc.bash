#!/bin/bash
set -ex

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

function darwin_gettext_install() {
  echo =================== installing gettext from ${GETTEXT_URL}
  downloadSource "${GETTEXT_URL}" "${GETTEXT_VERSION}" gettext
  makeAndGotoBuildDir darwin gettext
	PATH=${TOOLSDIR}/bin:$PATH ../../src/gettext-${GETTEXT_VERSION}/configure --prefix="$TOOLSDIR"
	make ${JOBS} install
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
  standardLib darwin "${FFI_URL}" "${FFI_VERSION}" libffi
  standardLib darwin "${LIBUNISTRING_URL}" "${LIBUNISTRING_VERSION}" libunistring
  standardLib darwin "${PCRE_URL}" "${PCRE_VERSION}" pcre
  standardLib darwin "${PCRE2_URL}" "${PCRE2_VERSION}" pcre2
  darwin_gettext_install
else
  echo feelings from scratch only works on Darwin right now
fi
