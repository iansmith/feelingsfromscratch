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

declare -a configOpts

function setupConfigOptsCrossCompile() {
  local os
  local tool
  os=${1}
  tool=${2}

  configOpts=()
  if [ "$os" == "darwin" ]; then
    configOpts+=("--host=x86_64-apple-darwin19.5.0")
    configOpts+=("--build=x86_64-apple-darwin19.5.0")
  else
    configOpts+=("--host=x86_64-linux-gnu")
    configOpts+=("--build=x86_64-linux-gnu ")
  fi
  configOpts+=("--target=aarch64-elf")
  configOpts+=("--prefix=${TOOLSDIR}")
  configOpts+=("--disable-shared")
  configOpts+=("--enable-libmpx")
  configOpts+=("--with-system-zlib")
  configOpts+=("--with-system-isl")
  configOpts+=("--with-system-isl")
  configOpts+=("--enable-__cxa_atexit")
  configOpts+=("-disable-libunwind-exceptions")
  configOpts+=("--enable-clocale=gnu")
  configOpts+=("--disable-libstdcxx-pch")
  configOpts+=("--disable-libssp")
  configOpts+=("--enable-plugin")
  configOpts+=("--enable-lto")
  configOpts+=("--enable-install-libiberty")
  configOpts+=("--with-linker-hash-style=gnu")
  configOpts+=("--enable-gnu-indirect-function")
  configOpts+=("--disable-multilib")
  configOpts+=("--disable-werror")
  configOpts+=("--enable-checking=release")
  configOpts+=("--enable-default-pie")
  configOpts+=("--enable-default-ssp")
  configOpts+=("--enable-gnu-unique-object")
  if [ "tool" == "binutils" ]; then
    configOpts+=("--enable-ld")
    configOpts+=("--enable-gold")
  else
    configOpts+=("--enable-languages=c")
    configOpts+=("--with-isl")
    configOpts+=("--with-gmp-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-gmp-include=${TOOLSDIR}/include")
    configOpts+=("--with-mpfr-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-mpfr-include=${TOOLSDIR}/include")
    configOpts+=("--with-mpc-lib=${TOOLSDIR}/lib")
    configOpts+=("--with-mpc-include=${TOOLSDIR}/include")
  fi

  if [ "$os" == "darwin" ]; then
    configOpts+=("--with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")
  fi
}

function binutils_install() {
  echo =================== installing binutils from ${BINUTILS_URL}
  downloadSource "${BINUTILS_URL}" "${BINUTILS_VERSION}" binutils binutils
  makeAndGotoBuildDir ${1} binutils
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/binutils-${BINUTILS_VERSION}/configure \
    --host=x86_64-linux-gnu --build=x86_64-linux-gnu --target=aarch64-elf --prefix=${TOOLDIR} \
    --disable-shared --enable-libmpx --with-system-zlib  --with-system-isl \
    --enable-__cxa_atexit -disable-libunwind-exceptions --enable-clocale=gnu \
    --disable-libstdcxx-pch --disable-libssp --enable-plugin \
    --enable-lto --enable-install-libiberty --with-linker-hash-style=gnu \
    --enable-gnu-indirect-function --disable-multilib --disable-werror \
    --enable-checking=release --enable-default-pie \
    --enable-default-ssp --enable-gnu-unique-object --enable-ld --enable-gold
  make ${JOBS}
  make install
  cd ../..
  return 0
}
function gcc_install() {
  echo =================== installing gcc from ${GCC_URL}
  downloadSource "${GCC_URL}" "${GCC_VERSION}" gcc gcc
  makeAndGotoBuildDir ${1} gcc
  PATH=${TOOLSDIR}/bin:${PATH} ../../src/gcc-${GCC_VERSION}/configure \
    --host=x86_64-linux-gnu --build=x86_64-linux-gnu --target=aarch64-elf --prefix=${TOOLDIR} \
    --enable-languages=c --enable-threads=posix --enable-libmpx --with-system-zlib \
    --with-isl --enable-__cxa_atexit --disable-libunwind-exceptions \
    --enable-clocale=gnu --disable-libstdcxx-pch --disable-libssp --enable-plugin \
    --disable-linker-build-id --enable-lto --enable-install-libiberty \
    --with-linker-hash-style=gnu --with-gnu-ld --enable-gnu-indirect-function \
    --disable-multilib --disable-werror --enable-checking=release --enable-default-pie \
    --enable-default-ssp --enable-gnu-unique-object \
    --with-gmp-lib=${TOOLSDIR}/lib --with-gmp-include=${TOOLSDIR}/include \
    --with-mpfr-lib=${TOOLSDIR}/lib --with-mpfr-include=${TOOLSDIR}/include \
    --with-mpc-lib=${TOOLSDIR}/lib --with-mpc-include=${TOOLSDIR}/include
    //--with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
  make ${JOBS}
  make install
  cd ../..
  return 0
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

export PATH=$FFS/tools/bin:$PATH
export LD_LIBRARY_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu
export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib
if [ "$OS" == "linux" ]; then
  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
else
  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
fi


#standardLib "${OS}" "${GMP_URL}" "${GMP_VERSION}" gmp -n -d
#standardLib ${OS} "${MPFR_URL}" "${MPFR_VERSION}" mpfr -n "--with-gmp=${TOOLSDIR}"
#standardLib ${OS} "${ISL_URL}" "${ISL_VERSION}" isl "--with-gmp-prefix=${TOOLSDIR}"
#standardLib ${OS} "${MPC_URL}" "${MPC_VERSION}" mpc "--with-gmp=${TOOLSDIR}"
#standardLib ${OS} "${CLOOG_URL}" "${CLOOG_VERSION}" cloog \
#  "--with-gmp-prefix=${TOOLSDIR}" "--with-isl-builddir=../darwin-isl"

#binutils_install ${OS}
#setupConfigOptsCrossCompile ${OS}  binutils
#standardLib "${OS}" "${BINUTILS_URL}" "${BINUTILS_VERSION}" binutils ${configOpts[@]}
#exit 0
#gcc_install ${OS}
setupConfigOptsCrossCompile ${OS}  gcc
standardLib "${OS}" "${GCC_URL}" "${GCC_VERSION}" gcc -p=aarch64-builtins.p1.patch ${configOpts[*]}
exit 0

#standardLib ${OS} ${QEMU_URL} ${QEMU_VERSION} --target-list=aarch64-softmmu --enable-debug