#!/bin/bash
set -ex

OPENSSL_VERSION="1_1_1g"
OPENSSL_URL="https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSL_VERSION}.tar.gz"
TASN1_VERSION="4.16.0"
TASN1_URL="https://ftp.gnu.org/gnu/libtasn1/libtasn1-${TASN1_VERSION}.tar.gz"
P11_VERSION="0.23.20"
P11_URL="https://github.com/p11-glue/p11-kit/releases/download/${P11_VERSION}/p11-kit-${P11_VERSION}.tar.xz"
IDN_VERSION="2.3.0"
IDN_URL="https://ftp.gnu.org/gnu/libidn/libidn2-${IDN_VERSION}.tar.gz"
UNBOUND_VERSION="1.10.1"
UNBOUND_URL="https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz"
NETTLE_VERSION="3.6"
NETTLE_URL="https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz"
GNUTLS_VERSION="3.6.9"
GNUTLS_SHORT_VERSION="3.6"
GNUTLS_URL="https://www.gnupg.org/ftp/gcrypt/gnutls/v${GNUTLS_SHORT_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz"
WGET_VERSION="1.99.2"
WGET_URL="https://ftp.gnu.org/gnu/wget/wget2-1.99.2.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash

function darwin_openssl_install() {
  echo =================== installing openssl from ${OPENSSL_URL}
  downloadSource "${OPENSSL_URL}" "${OPENSSL_VERSION}" openssl
  makeAndGotoBuildDir darwin openssl
  altname="OpenSSL_${OPENSSL_VERSION}"
  PATH=${TOOLSDIR}/bin:$PATH ../../src/openssl-${altname}/Configure \
    --prefix="${TOOLSDIR}" --openssldir="${TOOLSDIR}" "${1}"
  make ${JOBS} install
  cd ../..
  return 0
}


function darwin_p11kit_install() {
  echo =================== installing p11-kit from ${P11_URL}
  downloadSource "${P11_URL}" "${P11_VERSION}" p11-kit
  makeAndGotoBuildDir darwin p11-kit
  PATH=${TOOLSDIR}/bin:$PATH ../../src/p11-kit-${P11_VERSION}/configure \
    --prefix="$TOOLSDIR" --without-trust-paths
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_unbound_install() {
  echo =================== installing unbound from ${UNBOUND_URL}
  downloadSource "${UNBOUND_URL}" "${UNBOUND_VERSION}" unbound
  makeAndGotoBuildDir darwin unbound
  PATH=${TOOLSDIR}/bin:$PATH ../../src/unbound-${UNBOUND_VERSION}/configure \
    --prefix="$TOOLSDIR" --with-ssl=${TOOLSDIR} --with-libexpat=${TOOLSDIR} \
    --enable-fully-static --with-nettle=${TOOLSDIR}
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_gnutls_install() {
  echo =================== installing gnutls from ${GNUTLS_URL}
  downloadSource "${GNUTLS_URL}" "${GNUTLS_VERSION}" gnutls
  makeAndGotoBuildDir darwin gnutls
  LDFLAGS="-L${TOOLSDIR}/lib -v -read_only_relocs suppress" CFLAGS="-I${TOOLSDIR}/include" \
    PATH=${TOOLSDIR}/bin:$PATH PKG_CONFIG_PATH=${TOOLSDIR}/lib/pkgconfig \
    ../../src/gnutls-${GNUTLS_VERSION}/configure \
    --prefix="$TOOLSDIR" --enable-openssl-compatibility --with-pic
  make ${JOBS} install
  cd ../..
  return 0
}
function darwin_nettle_install() {
  echo =================== installing nettle from ${NETTLE_URL}
  downloadSource "${NETTLE_URL}" "${NETTLE_VERSION}" nettle
  makeAndGotoBuildDir darwin nettle
  PATH=${TOOLSDIR}/bin:$PATH ../../src/nettle-${NETTLE_VERSION}/configure \
     --disable-shared --prefix=${TOOLSDIR} --with-lib-path=${TOOLSDIR}/lib \
     --with-include-path=${TOOLSDIR}/include --enable-static --disable-pic
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
#  darwin_openssl_install darwin64-x86_64-cc
#  standardLib darwin "${TASN1_URL}" "${TASN1_VERSION}" libtasn1
#  darwin_p11kit_install
#  standardLib darwin "${IDN_URL}" "${IDN_VERSION}" libidn2
#  darwin_nettle_install
#  darwin_unbound_install
  darwin_gnutls_install
#  echo "=========== using WGET to test that our crypto libs are ok"
#  standardLib darwin "${WGET_URL}" "${WGET_VERSION}" wget2

else
  echo feelings from scratch only works on Darwin right now
fi
