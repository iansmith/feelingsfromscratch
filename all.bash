#!/bin/bash
set -e
#
# For the impatient
#

source utils.bash

## CRITICAL
PATH=/usr/bin:/bin:/usr/sbin:/sbin
echo setting your path to "$PATH" for safe building

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
#  ./math.bash
#  ./gnu-misc.bash
#  ./meta-build-tools.bash
  ./encodings.bash
  ./crypto.bash
  ./build-tools.bash
  ./primary-tools.bash

else
  echo feelings from scratch only works on Darwin right now
fi

