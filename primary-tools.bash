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
GDB_VERSION="9.2"
GDB_URL="https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz"
XZ_VERSION="5.2.5"
XZ_URL="https://sourceforge.net/projects/lzmautils/files/xz-${XZ_VERSION}.tar.gz/download"
GO_VERSION="1.14.4"
GO_URL="https://dl.google.com/go/go${GO_VERSION}.src.tar.gz"

TINYGO_GIT="https://github.com/tinygo-org/tinygo.git"
TINYGO_BRANCH="dev"

source utils.bash
declare -a configOpts

###
### check the vars  for state from utils.sh
###

if [ "${ARGS_PARSED}" == "" ]; then
  parseArgs "$*"
fi
if [ "${OS}" == "" ]; then
  getOS
fi
if [ "${TOOLSDIR}" == "" ]; then
  getToolsDir
fi

#
# bootstrap go compiler
#
function hostgo_install() {
  local os=${1}
  downloadSource "${GO_URL}" "${GO_VERSION}" "go" "go"
  mv src/go hostgo
  cd hostgo/src
  ./all.bash
  cd ../..
}

#
# tinygo compiler
#
function tinygo_install() {
  local os=${1}
  git clone --recursive ${TINYGO_GIT}
  cd tinygo
  git checkout ${TINYGO_BRANCH}
  make llvm-source
  make llvm-build
  make release
}

#
# special installer for pkg_config because needs special env vars
#
function pkgconfig_install() {
  local os=${1}
  local url=${PKGCONFIG_URL}
  local version=${PKGCONFIG_VERSION}
  local pkg=pkg-config

  echo =================== installing pkgconfig from ${url}
  downloadSource "${url}" "${version}" "${pkg}" "${pkg}"
  makeAndGotoBuildDir "${os}" "${pkg}"

  PATH=${TOOLSDIR}/bin:${PATH} \
    PKG_CONFIG_LIBDIR=${TOOLSDIR}/lib/pkgconfig \
    "../../src/${pkg}-${version}/configure" --prefix="${TOOLSDIR}" --with-internal-glib

  make "${JOBS}"
  make "${JOBS}" install
  cd ../..
  return 0
}

#
# ask user if we can proceed
#
function canContinue() {
  read -p "Continue [y/n]? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo aborting at user request.
    exit 1
  fi
  return
}

#
# check that their world is not in a broken state and they also have not run
# this script before
#
function pregame() {
  local os=${1}

  if [ "${os}" == "darwin" ]; then
    if [ "$DYLD_LIBRARY_PATH" != "" ]; then
      echo ====================================================================
      echo running this script with DYLD_LIBRARY_PATH set is likely to create
      echo key feelings tools \(binaries\) that have unexpected dependencies
      echo outside this tree. this is unlikely to be what you want.
      canContinue
      echo
      echo
    fi
  else
    if [ "${LD_LIBRARY_PATH}" != "" ]; then
      echo ====================================================================
      echo running this script with LD_LIBRARY_PATH set is likely to create
      echo key feelings tools \(binaries\) that have unexpected dependencies
      echo outside this tree. this is unlikely to be what you want.
      canContinue
      echo
      echo
    fi
  fi

  if [ "${PKG_CONFIG_PATH}" == "" ]; then
    echo ====================================================================
    echo your PKG_CONFIG_PATH variable is not set.  it frequently causes problems
    echo with the build of qemu if you do not have this set such that the build
    echo of qemu can find the installation of glib (version 2.54ish) that your
    echo package manager put in place.
    if [ "${OS}" == "darwin" ]; then
      echo On MacOS this means setting your PKG_CONFIG_PATH to point to the
      echo place your package manager puts *its* pkg-config `.pc` files.
      echo This is usually
      echo \'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig\'
    else
      echo On linux this means setting your PKG_CONFIG_PATH to point to the
      echo place your package manager puts *its* pkg-config `.pc` files.
      echo This is usually, but not always, something like this:
      echo \'export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig\'
    fi
    canContinue
    echo
    echo
  fi

  declare -a already
  set +e
  for i in qemu-system-aarch64 aarch64-elf-gdb aarch64-elf-gcc aarch64-elf-readelf aarch64-elf-objcopy; do
    local r
    r=$(command -v ${i})
    if [ "${r}" != "" ]; then
      already+=("${i}")
    fi
  done
  set -e

  if [ "${already[*]}" != "" ]; then
    echo ====================================================================
    echo we found some of the tools this script builds in your PATH:
    echo "${already[*]}"
    if [ -f "${TOOLSDIR}/bin/${already[0]}" ]; then
      echo
      echo these appear to be in the place this script will install binaries
      echo and this is usually ok.
      echo
      canContinue
    else
      echo Running this script with these tools already in your path can cause
      echo errors when this tools builds its copy of these tools. It is likely
      echo you have another package installed that includes these tools. It is
      # shellcheck disable=SC1010
      echo best to reset your PATH to make sure you do not have these in your
      echo PATH.
      canContinue
    fi
  fi

  local tmp
  tmp=$(command -v go)  #to avoid hostgo being just "true"
  local hostgo=${tmp}
  echo "tmp is $tmp and hostgo is $hostgo"
  if [ "${hostgo}" == "" ]; then
    # shellcheck disable=SC2153
    if [ "${HOSTGO}" != "" ]; then
      echo ====================================================================
      echo you have the HOSTGO variable set\! this is likely from running this
      echo script before. Further, your HOSTGO variable does not point to a
      echo go installation. You probably want to unset the HOSTGO variable.
      echo
      echo aborting, found HOSTGO variable but no bootstrap go installation in PATH
      exit 1
    fi
    echo ====================================================================
    echo we cannot find a copy of go in your PATH. This script uses a go
    # shellcheck disable=SC2035
    echo compiler *only* for bootstrapping the exact version of go that it
    echo needs. You need to install a copy of go that will be found in your
    echo PATH either via your package manager or from https://golang.org/dl/
    echo You need a version of go that is at least version 1.4, which is
    echo \"any modern go will do\".
    echo
    echo aborting, no bootstrap go compiler found in PATH
    exit 1
  fi
  if [ "$HOSTGO" != "" ]; then
    echo ====================================================================
    echo you have the HOSTGO variable set\! this is likely from running this
    echo script before. This is likely to cause confusion later when you
    echo use Makefiles that expect the HOSTGO variable to point to the newly
    # shellcheck disable=SC2016
    echo created binaries. You need to unset the '$HOSTGO' variable
    echo
    exit 1
  fi
  echo
  echo using "$hostgo" as bootstrap go compiler
}

#
# helper to make the list of options for binutils and gcc easier to manage
#
function setupConfigOptsCrossCompile() {
  local os=${1}
  local tool=${2}

  configOpts=()
  if [ "$os" == "darwin" ]; then
    configOpts+=("--host=x86_64-apple-darwin19.5.0")
  else
    configOpts+=("--host=x86_64-linux-gnu")
  fi
  configOpts+=("--target=aarch64-elf")
  configOpts+=("--prefix=${TOOLSDIR}")
  configOpts+=("--with-system-zlib")
  configOpts+=("--enable-install-libiberty")
  configOpts+=("--enable-multilib")
  configOpts+=("--enable-checking=release")
  configOpts+=("--disable-nls")
  configOpts+=("--disable-shared")
  configOpts+=("--with-gcc")
  configOpts+=("--with-gnu-as")
  configOpts+=("--with-gnu-ld")
  if [ "${tool}" == "binutils" ]; then
    configOpts+=("--enable-ld")
    #configOpts+=("--enable-gold")
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

}

#
# explain to the user how to set their env vars
#
function postgame() {
  echo ====================================================================
  echo
  echo with the tools now built, you probably want to set your
  echo PKG_CONFIG_PATH to ensure that you have the pkg-config files created
  echo by this tool first.
  echo
  if [ "$OS" == "linux" ]; then
    echo "on linux this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig'
  else
    echo "on MacOS this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig'
  fi
  echo
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo
  echo To insure you are using the feelings version of the tools, you will want
  echo to set your PATH to have the freshly built tools first. In some cases
  echo we are intentially overriding already installed binaries.
  echo
  if [ "$OS" == "linux" ]; then
    echo "for example, on linux this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PATH=$FFS/tools/bin/:/usr/local/bin:/usr/bin:/bin/usr/sbin:/sbin'
  else
    echo "for example, on MacOS this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PATH=$FFS/tools/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
  fi
  echo
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo
  echo
  # shellcheck disable=SC2035
  echo You will want to make sure you get *exactly* the right version of the
  echo libraries we have just installed by putting this scripts lib directory
  echo first in your dynamic library path.
  echo
  if [ "$OS" == "linux" ]; then
    echo "on linux this might look like this:"
    # shellcheck disable=SC2016
    echo 'export LD_LIBRARY_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu'

  else
    echo "on MacOS this might look like this:"
    # shellcheck disable=SC2016
    echo 'export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib'
  fi
  echo
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo
  echo This script created its own copy of pkg-config to manage the libraries
  echo whose versions are critical. You will want to be sure the pkg-config
  echo "storage location" for .pc files has the newly constructed libarries\'
  echo entries first.
  echo
  if [ "$OS" == "linux" ]; then
    echo "on linux this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PKG_CONFIG_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu/pkgconfig'

  else
    echo "on MacOS this might look like this:"
    # shellcheck disable=SC2016
    echo 'export PKG_CONFIG_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib'
  fi
  echo
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo
  echo This script built a particular version of go that it needs for its
  echo host programs.  You will want to set the environment variable HOSTGO
  echo like this:
  # shellcheck disable=SC2016
  echo 'export HOSTGO=$FFS/hostgo'
  echo
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo
  echo If you intstalled a go compiler just to bootstrap feelings, this is
  echo a good time to remove it.
  read -p "press a key to continue" -n 1 -r
  echo
  if [ "${OS}" == "darwin" ]; then
    echo ====================================================================
    echo
    echo You will need to follow the intstructions at the URL below to codesign
    echo your debugger \'"${TOOLSDIR}/bin/aarch64-bin-gdb"\' so that MacOS will
    echo allow it to have debug priveliges.
    echo
    echo
    read -p "press a key to continue" -n 1 -r
    echo
  fi
  echo ====================================================================
  echo You will need to use your feelings source code  installation in the
  echo directory \"modtinygo\" to install the raspberry pi 3 targets into tinygo.
  echo These files are kept with feelings rather than Feelings From Scratch
  echo because they are truly source code and they change frequently.
  echo
  echo Use \'make\' in the \"modifytinygo\" directory to install the most
  echo recent version of these files into your tinygo installation.
  read -p "press a key to continue" -n 1 -r
  echo ====================================================================
  echo Yay! done. exit 0!
}

# sanity check
pregame "${OS}"

###
### Install procedure
###
#
# pkg config has to come first
pkgconfig_install "${OS}"
#qemu can get confused if you don't make it abundantly clear *which* version of
#glib you are building for, so we do it early when we can be reasonably sure it
#will pick up the one from the package manager
standardLib "${OS}" "${QEMU_URL}" "${QEMU_VERSION}" qemu -d --target-list=aarch64-softmmu \
  "--prefix=${TOOLSDIR}"

export PATH=$FFS/tools/bin:$PATH
export LD_LIBRARY_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu
export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib
if [ "$OS" == "linux" ]; then
  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
else
  export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
fi

# libraries we want to be controlled by us, not package manager...
# this also means that they appear in our pkg-config, which should be
# be first in the path of pkg-config
standardLib "${OS}" "${GMP_URL}" "${GMP_VERSION}" gmp -n
standardLib "${OS}" "${MPFR_URL}" "${MPFR_VERSION}" mpfr -n "--with-gmp=${TOOLSDIR}"
standardLib "${OS}" "${ISL_URL}" "${ISL_VERSION}" isl "--with-gmp-prefix=${TOOLSDIR}"
standardLib "${OS}" "${MPC_URL}" "${MPC_VERSION}" mpc "--with-gmp=${TOOLSDIR}"
standardLib "${OS}" "${CLOOG_URL}" "${CLOOG_VERSION}" cloog \
  "--with-gmp-prefix=${TOOLSDIR}" "--with-isl-builddir=../darwin-isl"
standardLib "${OS}" "${XZ_URL}" "${XZ_VERSION}" xz

#just the source of newlib, used to build gcc later
downloadSource "${NEWLIB_URL}" "${NEWLIB_VERSION}" newlib newlib

#binutils
setupConfigOptsCrossCompile "${OS}" binutils
standardLib "${OS}" "${BINUTILS_URL}" "${BINUTILS_VERSION}" binutils ${configOpts[@]}

#gcc
setupConfigOptsCrossCompile "${OS}" gcc
standardLib "${OS}" "${GCC_URL}" "${GCC_VERSION}" gcc \
  -p=aarch64-builtins.p1.patch ${configOpts[*]}

#gdb
standardLib "${OS}" "${GDB_URL}" "${GDB_VERSION}" gdb --target=aarch64-elf \
  "--prefix=${TOOLSDIR}" --disable-shared

hostgo_install "${OS}"
tinygo_install "${OS}"

# tell the user what to do now
#postgame
