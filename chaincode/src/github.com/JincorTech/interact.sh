#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit
[ -z "$2" ] && echo 'Specify organization' && exit
[ -z "$3" ] && echo 'Specify channel name' && exit
[ -z "$4" ] && echo 'Specify method (init, invoke, query)' && exit
[ -z "$5" ] && echo 'Specify json serialized args' && exit

cd $(dirname $(type -p $0))

source /opt/sandbox/scripts/shared/functions.sh

setVarsForPeer $2 0

function initChaincode() {
    cmd=$1

    shift

    [ -z "$6" ] && echo 'Specify version' && exit

    if [ -n "$7" ]; then
        policy="-P $7"
    fi

    peer chaincode $cmd -C $3 -n $1 -v $6 -c "$5" $policy -o orderer.jincor.com:7050 \
        --vscc vscc --escc escc \
        --tls --cafile $ORDERER_CA
}

function callChaincode() {
    peer chaincode $4 -C $3 -n $1 -c "$5" -o orderer.jincor.com:7050 \
        --tls --cafile $ORDERER_CA
}

if [ "$4" == "init" ] || [ "$4" == "up" ]; then
    cmd="instantiate"
    if [ "$4" == "up" ]; then
        cmd="upgrade"
    fi
    initChaincode $cmd $@
else
    callChaincode $@
fi
