#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit
[ -z "$2" ] && echo 'Specify organization' && exit
[ -z "$3" ] && echo 'Specify channel name' && exit
[ -z "$4" ] && echo 'Specify method (init, invoke, query)' && exit
[ -z "$5" ] && echo 'Specify json serialized args' && exit

source /opt/sandbox/scripts/shared/functions.sh

setVarsForPeer $2 0

function initChaincode() {
    peer chaincode instantiate -C $3 -n $1 -v 0 -c "$5" -o orderer.jincor.com:7050 \
        --tls --cafile $ORDERER_CA
}

function callChaincode() {
    peer chaincode $4 -C $3 -n $1 -c "$5" -o orderer.jincor.com:7050 \
        --tls --cafile $ORDERER_CA
}

if [ "$4" == "init" ]; then
    initChaincode $@
else
    callChaincode $@
fi
