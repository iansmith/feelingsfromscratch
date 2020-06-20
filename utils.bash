OS=""
TOOLSDIR=""
JOBS=${JOBS:-""}
SILENT=${SILENT:-""}
WARN=""
if [ "${SILENT}" == "--silent" ]; then
  WARN="-w"
fi


function getToolsDir() {
  mkdir -p tools
  cd tools
  TOOLSDIR=$(pwd)
  cd ..
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
  mkdir -p src
  rm -rf "src/${3}-${2}"
  file="${3}-${2}src.tar.gz"
  curl -L -o "./src/${file}" "${1}"
  cd src
  tar xzf "${file}"
  cd ..
  return 0
}

function makeAndGotoBuildDir() {
  builddir=build/${1}-${2}
  rm -rf ${builddir}
  mkdir -p ${builddir}
  cd ${builddir}
}


# if you use the altname, you have to supply the separator
function standardLibWithGmp {
  echo =================== installing ${5} from ${3}
  if [ "${6}" == "" ]; then
    altname="${5}-"
  else
    altname=${6}
  fi
  downloadSource "${3}" "${4}" "${5}"
  makeAndGotoBuildDir ${1} "${5}"
  PATH=${TOOLSDIR}/bin:$PATH CFLAGS=${WARN} ../../src/${altname}${4}/configure --disable-shared \
  --${2}=${TOOLSDIR} --prefix="$TOOLSDIR" ${SILENT}
  make ${JOBS} install
  cd ../..
  return 0
}

# if you use the altname, you have to supply the separator
function standardLib() {
  echo =================== installing ${4} from ${2}
  if [ "${5}" == "" ]; then
    altname="${4}-"
  else
    altname=${5}
  fi
  downloadSource "${2}" "${3}" "${4}"
  makeAndGotoBuildDir ${1} "${4}"
  PATH=${TOOLSDIR}/bin:$PATH CFLAGS=${WARN} ../../src/${altname}${3}/configure \
	${SILENT} --disable-shared --prefix="$TOOLSDIR" 
  make ${JOBS} install
  cd ../..
  return 0
}

