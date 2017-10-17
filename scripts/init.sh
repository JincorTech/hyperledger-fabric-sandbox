#!/usr/bin/env /bin/bash

[ -z $(which docker-compose) ] && echo 'Install docker-compose first!' && exit

cd $(dirname $(type -p $0))

pwd=${PWD}

cd tools
if [ ! -e "bin" ]; then
    echo 'Install tools...'
    ./install-tools.sh
fi

cd $pwd/../artifacts
if [ ! -e "channels" ]; then
    echo 'Make blocks and channels...'
    ./make.sh clean cryptogen channels devopsenv
fi

cd $pwd
if [ -z "$(docker ps -a | grep orderer.jincor.com)" ]; then
    echo 'Up docker containers...'
    ./containers-control.sh up
    ./containers-control.sh exec cli.jincor.com /opt/sandbox/scripts/create-channels.sh yes
    ./containers-control.sh exec cli.jincor.com /opt/sandbox/scripts/install-chaincodes.sh yes
fi

echo 'Done!'
