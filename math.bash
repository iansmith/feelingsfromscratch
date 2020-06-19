#!/bin/bash
set -e


GMP_VERSION="6.2.0"
GMP_URL="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
MPFR_VERSION="4.0.2"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.gz"
ISL_VERSION="0.18"
ISL_URL="http://isl.gforge.inria.fr/isl-${ISL_VERSION}.tar.gz"
CLOOG_VERSION="0.18.4"
CLOOG_URL="http://www.bastoul.net/cloog/pages/download/cloog-${CLOOG_VERSION}.tar.gz"
MPC_VERSION="1.1.0"
MPC_URL="https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz"

OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}

source utils.bash


function darwin_cloog_install() {
  echo =================== installing cloog from ${CLOOG_URL}
  downloadSource "${CLOOG_URL}" "${CLOOG_VERSION}" cloog
  makeAndGotoBuildDir darwin cloog
  PATH=${TOOLSDIR}/bin:$PATH ../../src/cloog-${CLOOG_VERSION}/configure --disable-shared \
    --prefix="$TOOLSDIR" --with-gmp-prefix=${TOOLSDIR} --with-isl-builddir=../darwin-isl
  make ${JOBS} install
  cd ../..
  return 0
}

function darwin_gmp_install() {
  echo =================== installing gmp from ${GMP_URL}
  downloadSource "${GMP_URL}" "${GMP_VERSION}" gmp
  makeAndGotoBuildDir darwin gmp
  PATH=${TOOLSDIR}/bin:$PATH ../../src/gmp-${GMP_VERSION}/configure \
    --prefix="$TOOLSDIR"
  make ${JOBS} install
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
  darwin_gmp_install
  standardLib darwin "${GMP_URL}" "${GMP_VERSION}" gmp
  standardLibWithGmp darwin "${MPFR_URL}" "${MPFR_VERSION}" mpfr
  standardLibWithGmp darwin "${ISL_URL}" "${ISL_VERSION}" isl
  standardLibWithGmp darwin "${MPC_URL}" "${MPC_VERSION}" mpc
  darwin_cloog_install
else
  echo feelings from scratch only works on Darwin right now
fi

