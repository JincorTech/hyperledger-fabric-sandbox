#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit

cd $1

CORE_CHAINCODE_ID_NAME=$1:0 ./$1

cd ..
