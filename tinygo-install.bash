#!/bin/bash

set -e

TINYGO_GITURL='git@github.com:tinygo-org/tinygo.git'
COMMIT_ID="c5a8967"

function getOS {
	os=`uname -s`
	if [ "$os" == "" ]; then
		echo unable to determine OS, uname -s returned nothing
		exit 1
	fi

	if [ "$os" != "Darwin" ]; then
		echo current feelings from scratch only works on Darwin
		exit 1
	fi
	OS=$os
	return 0
}

function darwin_tinygo_install() {
  git clone "$TINYGO_GITURL"
  cd tinygo
  git checkout "$COMMIT_ID"
  make llvm-source
  make llvm-build
  make
  cd ..
}


##
## START
##

getOS
if [ "$OS" == "Darwin" ]; then
	darwin_tinygo_install
	if [ "$?" != "0" ]; then
		exit 1
	fi
else
	echo feelings from scratch only works on Darwin right now
fi

echo ----------
echo tinygo has been installed at commit id ${COMMIT_ID}
echo ----------
echo Please add `pwd`/tinygo/build and `pwd`/tinygo/llvm-build/bin to your PATH
echo variable now.
echo
echo Verify your tinygo installation with \'which tinygo\` and \'tinygo version\'
