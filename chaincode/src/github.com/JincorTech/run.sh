#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit
[ -z "$2" ] && echo 'Specify org name' && exit
[ -z "$2" ] && echo 'Specify version' && exit

cd $(dirname $(type -p $0))

source /opt/sandbox/scripts/shared/functions.sh

setVarsForPeer $2 0

cd $1

CORE_CHAINCODE_ID_NAME=$1:$3 ./$1

cd ..
