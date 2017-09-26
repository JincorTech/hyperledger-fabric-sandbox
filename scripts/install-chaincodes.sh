#!/usr/bin/env /bin/bash

[ "$1" != "yes" ] && echo 'Specify yes as argument' && exit

cd $(dirname $(type -p $0))

pwd=$PWD

source ./shared/functions.sh

src_folder=/opt/gopath/src/github.com/JincorTech

cd $src_folder

echo 'Install chaincodes...'

for src in chaincode1 chaincode2; do
    echo "Build and install $src..."
    ./make.sh $src
    ./install.sh $src "org1 org2"
done

echo 'Done!'
