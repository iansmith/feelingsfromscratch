#!/bin/bash

set -e

TINYGO_GITURL='git@github.com:tinygo-org/tinygo.git'
COMMIT_ID="c5a8967"

sourc utils.bash

function darwin_tinygo_install() {
  git clone "$TINYGO_GITURL"
  cd tinygo
  git checkout "$COMMIT_ID"
  PATH=${TOOLSDIR}/bin:$PATH make llvm-source
  PATH=${TOOLSDIR}/bin:$PATH make llvm-build
  PATH=${TOOLSDIR}/bin:$PATH make
  cd ..
}


##
## START
##

getOS
if [ "$OS" == "darwin" ]; then
	darwin_tinygo_install
	if [ "$?" != "0" ]; then
		exit 1
	fi
else
	echo feelings from scratch only works on Darwin right now
fi
