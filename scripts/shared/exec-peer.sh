#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify org' && exit
[ -z "$2" ] && echo 'Specify peer' && exit

cd $(dirname $0)

pwd=$PWD

source ./functions.sh

orderer="orderer"

if [ "${JINCOR_NETWORK_TYPE}" == "orderers" ]; then
  orderer="orderer0"
fi

setVarsForPeer $1 $2
shift 2
peer $@ -o $orderer.jincor.com:7050 \
    --tls --cafile $ORDERER_CA
