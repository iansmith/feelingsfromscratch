
function getToolsDir() {
  mkdir -p tools
  cd tools
  TOOLSDIR=$(pwd)
  cd ..
  if [ "${TOOLSDIR}" == "" ]; then
    echo unable to determine where the tools dir is, aborting
    exit 1
  fi
  return 0
}

function getOS() {
  os=$(uname -s)
  if [ "$os" == "" ]; then
    echo unable to determine OS, uname -s returned nothing
    exit 1
  fi
  if [ "$os" != "Darwin" ]; then
    if [ "$os" != "Linux" ]; then
      echo currently feelings from scratch only works on Darwin and Linux
      exit 1
    fi
    OS="linux"
  else
    OS="darwin"
  fi
  return 0
}

# must be called from base dir
function downloadSource() {
  ## required args
  url=${1}
  version=${2}
  pkg=${3}
  altname=${4}
  shift; shift; shift

  local tarargs
  tarargs="xzf"
  if [ "${OS}" == "linux" ]; then
    tarargs="xaf"
  fi

  local file
  local dir
  mkdir -p src
  file="${pkg}-${version}src.tar.gz"
  dir="${altname}-${version}"
  if [ -f "src/${file}" ] && [ -d "src/${dir}" ]; then
    echo using existing version of downloaded lib ${1}
  else
    echo =================== downloading ${pkg} from ${url}
    rm -rf "src/${pkg}-${version}"
    curl -L -o "./src/${file}" "${url}"
    cd src
    tar "${tarargs}" "${file}"
    cd ..
  fi
  return 0
}

function makeAndGotoBuildDir() {
  ## required args
  platform="${1}"
  pkg="${2}"
  shift; shift

  builddir="build/${platform}-${pkg}"
  rm -rf "${builddir}"
  mkdir -p "${builddir}"
  cd "${builddir}"
}


function standardLib() {
  local platform
  local url
  local version
  local pkg
  ## required args
  platform="${1}"
  url="${2}"
  version="${3}"
  pkg="${4}"
  shift; shift; shift; shift

  local altname
  local patches
  local nosilent
  local nostatic
  local ldflags
  local cflags
  local autogen
  altname="${pkg}"
  patches=()
  while [[ $# -gt 0 ]]; do
    case ${1} in
    #it doesn't unpack into the obvious name, so we give name
    -a=*)
      altname="${1#*=}"
      shift
      ;;
    -n)  #nosilent
      nosilent="true"
      shift
      ;;
    -g)  #autogen first
      autogen="true"
      shift
      ;;
    -d)  ##dynamic only
      nostatic="true"
      shift
      ;;
    -f)  ## on darwin, link foundations in
      if [ "${OS}" == "darwin" ]; then
        ldflags+="-framework CoreFoundation -framework Foundation -framework AppKit"
      fi
      shift
      ;;
    -l=*)  ## on darwin, link foundations in
      flags="${1#*=}"
      ldflags+="${flags}"
      shift
      ;;
    -c=*)  ## cflags
      flags="${1#*=}"
      cflags+="${flags}"
      shift
      ;;
    #list of patches to use
    -p=*)
      patches+=" ${1#*=}"
      shift
      ;;
    *)
      break
      ;;
    esac
  done
  ### deal with any configure arguments
  declare -a configureArgs
  if [ "${nostatic}" == "" ]; then
    configureArgs+=" --disable-shared"
  fi
  configureArgs+=" --prefix=${TOOLSDIR}"
  if [ "${SILENT}" != "" ] && [ "${nosilent}" == "" ]; then
    configureArgs+=" ${SILENT}"
  fi
  while [[ $# -gt 0 ]]; do
    configureArgs+=" ${1}"
    shift
  done
  #check for warn suppresion via -s
  CFLAGS+=${WARN}

  downloadSource "${url}" "${version}" "${pkg}" "${altname}"
  #for packages that need autogen before build
  if [ "$autogen" != "" ]; then
    local dir
    dir="${altname}-${version}"
    cd "src/${dir}"
    PATH=${TOOLSDIR}/bin:$PATH ./autogen.sh
    cd ../..
  fi
  #awful that patch makes us do this, but blame larry wall
  set +e
  # for any of our local patches
  for i in ${patches[@]}; do
    dry=`patch -p0 -N --dry-run --silent -f < "$i"`
    if [ "${dry}" == "" ]; then
      echo patch "${i}"
      echo =================== applying patch $i
      patch -p 0 < "$i"
    else
      echo =================== detected preiously applied patch $i
    fi
  done
  set -e # normal service resumes

  makeAndGotoBuildDir ${platform} "${pkg}"
  echo =================== builing ${pkg}
  LIBTOOLIZE_OPTIONS=${LIBTOOL_SILENT} \
    PATH=${TOOLSDIR}/bin:$PATH CFLAGS+=${WARN} \
    PKG_CONFIG_PATH=${TOOLSDIR}/lib/pkgconfig:${PKG_CONFIG_PATH} \
    PKG_CONFIG=${TOOLSDIR}/bin/pkg-config \
    LDFLAGS=${ldflags} \
    CFLAGS=${cflags} \
    ../../src/${altname}-${version}/configure ${configureArgs[@]}
  LIBTOOLIZE_OPTIONS=${LIBTOOL_SILENT} make ${MAKESILENT} ${JOBS}
  echo ===================  installing ${pkg} to ${TOOLSDIR}

  LIBTOOLIZE_OPTIONS=${LIBTOOL_SILENT} make ${MAKESILENT} ${JOBS} install
  cd ../..
  return 0
}

function parseArgs() {
  ARGS_PARSED=true
  JOBS="-j=1"
  while [[ $# -gt 0 ]]; do
    case ${1} in
      -s)
        SILENT="--silent"
        WARN="-w"
        MAKESILENT="-s"
        LIBTOOL_SILENT="--quiet --no-warn"
        shift
        ;;
      -j=*)
        j="${1#*=}"
        JOBS="-j${j}"
        shift
        ;;
      -x)
        set -x
        shift
        ;;
      *)
        echo unknown command line option, use -s for silent, -x for shell echo, or -j=N where n is number of jobs
        exit 1
    esac
  done
  return 0
}

