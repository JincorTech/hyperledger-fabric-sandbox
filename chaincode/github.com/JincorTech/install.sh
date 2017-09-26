#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit
[ -z "$2" ] && echo 'Specify orgs for deploying' && exit

source /opt/sandbox/scripts/shared/functions.sh

for org in $2; do
    for peer in 0; do
        setVarsForPeer $org $peer
        peer chaincode install -p github.com/JincorTech/$1 -n $1 -v 0
    done
done
