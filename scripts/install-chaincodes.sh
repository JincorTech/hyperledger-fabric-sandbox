#!/usr/bin/env /bin/bash

[ "$1" != "yes" ] && echo 'Specify yes as argument' && exit

cd $(dirname $(type -p $0))

pwd=$PWD

source ./shared/functions.sh

src_folder=/opt/gopath/src/github.com/JincorTech

cd $src_folder

echo 'Install chaincodes...'

for src in chaincode1 chaincode2 chaincode3; do
    echo "Build $src..."
    ./make.sh $src
done

if [ "$2" = "org3" ]; then
    ./install.sh chaincode3 "org3" 0
else
    ./install.sh chaincode1 "org1" 0
    ./install.sh chaincode2 "org2" 0
fi

echo 'Done!'
