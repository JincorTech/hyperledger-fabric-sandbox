#!/usr/bin/env /bin/bash

cd $(dirname $(type -p $0))

export USER_ID=$(id -u)

JINCOR_NETWORK_TYPE=${JINCOR_NETWORK_TYPE:-base}

function dockercompose(){
    set -a
    source ../devops/.env
    docker-compose -f ../devops/docker-compose-$JINCOR_NETWORK_TYPE.yaml $@
}

function dkcl(){
    CONTAINER_IDS=$(docker ps -aq)
    echo
    if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
        echo "========== No containers available for deletion =========="
    else
        docker rm -f $CONTAINER_IDS
    fi
    echo
}

function dkrm(){
    DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
    echo
    if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
        echo "========== No images available for deletion ==========="
    else
        docker rmi -f $DOCKER_IMAGE_IDS
    fi
    echo
}

function down(){
    dockercompose down $@
    docker stop $(docker ps | awk '/dev-peer/{printf $1" "}')
    docker rm $(docker ps -a | awk '/dev-peer/{printf $1" "}')
    docker rmi $(docker images | awk '/dev-peer/{printf $1":latest "}')

    rm -rf /tmp/hfc-test-kvs_peerOrg* $HOME/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*
}

function exec() {
    dockercompose exec $@
}

function up() {
    dockercompose up -d $@
}

function stop() {
    dockercompose stop $@
}

function start() {
    dockercompose start $@
}

function restart() {
    stop
    start
}

function redeploy() {
    down
    up
}

cmd=$1

if [ -z "$cmd" ]; then
    echo 'Please, specify any command!'
    exit
fi

shift

if [ ! -n "$(type -t $cmd)" ] || [ ! "$(type -t $cmd)" = "function" ]; then
    echo "Unknown command $cmd"
    exit
fi

$cmd $@
