#!/bin/bash

set -e

GO_VERSION="1.14.4"

GO_DOWNLOAD_URL="https://dl.google.com/go/go${GO_VERSION}.src.tar.gz"

source utils.bash

function darwin_bootstrap_go() {
	bootstrapCompiler=`which go`
	if [ "$bootstrapCompiler" == "" ]; then
		echo unable to find bootstrap go compiler 
		echo perhaps update your PATH?
		exit 1
	fi
	curl -o ./go${GO_VERSION}src.tar.gz "$GO_DOWNLOAD_URL"
	tar xzf ./go${GO_VERSION}src.tar.gz
	cd ./go/src 
	echo changed directory to `pwd` to build host go compiler
	GOROOT_BOOTSTRAP="${bootstrapCompiler}" ./all.bash
	cd ../..
	mv go hostgo
	return 0
}


##
## START
##

getOS
if [ "$OS" == "darwin" ]; then
	darwin_bootstrap_go
	if [ "$?" != "0" ]; then
		exit 1
	fi
else
	echo feelings from scratch only works on Darwin right now
fi

echo ----------
echo go ${VERSION} has been installed.
echo ----------
echo Please add `pwd`/hostgo/bin to your PATH variable now
echo and remove your other go compiler \( bootstrap compiler \) from your PATH.
echo
echo Verify your hostgo installation with \'which go\` and \'go version\'


