#!/bin/bash
set -e


PKGCONFIG_VERSION="0.29.2"
PKGCONFIG_URL="https://pkg-config.freedesktop.org/releases/pkg-config-${PKGCONFIG_VERSION}.tar.gz"
BINUTILS_VERSION="2.34"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz"
GCC_VERSION="10.1.0"
GCC_URL="https://bigsearcher.com/mirrors/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
QEMU_VERSION="5.0.0"
QEMU_URL="https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz"
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
NEWLIB_VERSION="3.3.0"
NEWLIB_URL="ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz"


source utils.bash



###
### start
###

if [ "${ARGS_PARSED}" == "" ]; then
  parseArgs $*
fi
if [ "${OS}" == "" ]; then
  getOS
fi
if [ "${TOOLSDIR}" == "" ]; then
  getToolsDir
fi

function pkgconfig_install() {
  local os
  local url
  local version
  local pkg

  os=${1}
  url=${PKGCONFIG_URL}
  version=${PKGCONFIG_VERSION}
  pkg=pkg-config
  echo =================== installing pkgconfig from ${url}
  downloadSource "${url}" "${version}" ${pkg} ${pkg}
  makeAndGotoBuildDir ${os} ${pkg}

  PATH=${TOOLSDIR}/bin:${PATH} \
    PKG_CONFIG_LIBDIR=${TOOLSDIR}/lib/pkgconfig \
    ../../src/${pkg}-${version}/configure --prefix=${TOOLSDIR} --with-internal-glib

  make ${JOBS}
  make ${JOBS} install
  cd ../..
  return 0
}

function gcc_stage1_install() {
  local os
  local url=${GCC_URL}
  local version=${GCC_VERSION}
  local pkg=gcc

  os=${1}
  url=${PKGCONFIG_URL}
  version=${PKGCONFIG_VERSION}
  pkg=pkg-config
  echo =================== installing gcc_stage from ${url}
  downloadSource "${url}" "${version}" ${pkg} ${pkg}
  makeAndGotoBuildDir ${os} ${pkg}

  PATH=${TOOLSDIR}/bin:${PATH} \
    PKG_CONFIG_LIBDIR=${TOOLSDIR}/lib/pkgconfig \
    ../../src/${pkg}-${version}/configure --prefix=${TOOLSDIR} --with-internal-glib

  setupConfigOptsCrossCompile ${OS}  gcc
  mkdir -p libiberty libcpp fixincludes
  PATH=${TOOLSDIR}/bin:${PATH} make ${JOBS} all-gcc
  PATH=${TOOLSDIR}/bin:${PATH} make ${JOBS} install-gcc

  cd ../..
  return 0
}

declare -a configOpts

function setupConfigOptsCrossCompile() {
  local os
  local tool

  os=${1}
  tool=${2}

  configOpts=()
  configOpts+=("-v")
  if [ "$os" == "darwin" ]; then
    configOpts+=("--host=x86_64-apple-darwin19.5.0")
  else
    configOpts+=("--host=x86_64-linux-gnu")
  fi
  configOpts+=("--target=aarch64-elf")
  configOpts+=("--prefix=${TOOLSDIR}")
  configOpts+=("--with-system-zlib")
  configOpts+=("--enable-install-libiberty")
  configOpts+=("--with-linker-hash-style=gnu")
  configOpts+=("--enable-multilib")
  configOpts+=("--enable-checking=release")
  configOpts+=("--disable-nls")
  configOpts+=("--disable-shared")
  configOpts+=("--disable-threads")
  configOpts+=("--with-gcc")
  configOpts+=("--with-gnu-as")
  configOpts+=("--with-gnu-ld")
  if [ "tool" == "binutils" ]; then
    configOpts+=("--enable-ld")
    configOpts+=("--enable-gold")
  else
    configOpts+=("--with-headers=src/newlib-${NEWLIB_VERSION}/newlib/libc/include")
    configOpts+=("--with-isl")
    configOpts+=("--enable-languages=c")
    configOpts+=("--with-newlib")
    configOpts+=("--disable-libssp")
    configOpts+=("--disable-libstdcxx-pch")
    configOpts+=("--disable-libmudflap")
    configOpts+=("--disable-libgomp")
    configOpts+=("--with-gmp-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-gmp-include=${TOOLSDIR}/include")
    configOpts+=("--with-mpfr-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-mpfr-include=${TOOLSDIR}/include")
    configOpts+=("--with-mpc-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-mpc-include=${TOOLSDIR}/include")
  fi

#  if [ "$os" == "darwin" ]; then
#    configOpts+=("--with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk")
#  fi
}

##
## START
##

if [ "${ARGS_PARSED}" == "" ]; then
  parseArgs $*
fi
if [ "${OS}" == "" ]; then
  getOS
fi
if [ "${TOOLSDIR}" == "" ]; then
  getToolsDir
fi

#pkgconfig_install ${OS}
#
#export PATH=$FFS/tools/bin:$PATH
#export LD_LIBRARY_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu
#export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib
#if [ "$OS" == "linux" ]; then
#  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
#else
#  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
#fi
#
#
#standardLib "${OS}" "${GMP_URL}" "${GMP_VERSION}" gmp -n -d
#standardLib ${OS} "${MPFR_URL}" "${MPFR_VERSION}" mpfr -n "--with-gmp=${TOOLSDIR}"
#standardLib ${OS} "${ISL_URL}" "${ISL_VERSION}" isl "--with-gmp-prefix=${TOOLSDIR}"
#standardLib ${OS} "${MPC_URL}" "${MPC_VERSION}" mpc "--with-gmp=${TOOLSDIR}"
#standardLib ${OS} "${CLOOG_URL}" "${CLOOG_VERSION}" cloog \
#  "--with-gmp-prefix=${TOOLSDIR}" "--with-isl-builddir=../darwin-isl"
#
##just the source of newlib, used to build gcc later
#downloadSource "${NEWLIB_URL}" "${NEWLIB_VERSION}" newlib newlib
#setupConfigOptsCrossCompile ${OS}  binutils
#standardLib "${OS}" "${BINUTILS_URL}" "${BINUTILS_VERSION}" binutils ${configOpts[@]}
#gcc_stage1_install ${OS}

setupConfigOptsCrossCompile ${OS}  gcc
standardLib "${OS}" "${GCC_URL}" "${GCC_VERSION}" gcc \
  -p=aarch64-builtins.p1.patch ${configOpts[*]}
exit 0

#standardLib ${OS} ${QEMU_URL} ${QEMU_VERSION} --target-list=aarch64-softmmu --enable-debug
