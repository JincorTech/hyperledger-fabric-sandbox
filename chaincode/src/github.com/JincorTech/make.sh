#!/usr/bin/env /bin/bash

[ -z "$1" ] && echo 'Specify folder name' && exit

cd $(dirname $(type -p $0))

cd $1

echo 'Download shim package...'
[ -d "$GOPATH/src/github.com/hyperledger/fabric/core/chaincode/shim" ] || go get -u --tags nopkcs11 github.com/hyperledger/fabric/core/chaincode/shim

echo 'Build...'
go build --tags nopkcs11

cd ..

echo 'Done!'
