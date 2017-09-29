#!/usr/bin/env /bin/bash

[ "$1" != "yes" ] && echo 'Specify yes as argument' && exit

cd $(dirname $(type -p $0))

pwd=$PWD

source ./shared/functions.sh

channels_folder=/opt/sandbox/artifacts/channels

function createChannel() {
    org=$1
    channelName=$2
    cd $channels_folder/${channelName}/
    echo $channels_folder/${channelName}/
    echo "Create ${channelName} channel..."
    setVarsForPeer $org 0
    peer channel create -c ${channelName} -f $channels_folder/${channelName}/${channelName}.tx -o orderer.jincor.com:7050 \
        --tls --cafile $ORDERER_CA
    cd $pwd
}

function joinAndUpdatePeer() {
    channelName=$1
    orgs=$2
    peers=$3
    for org in $orgs; do
        for peer in $peers; do
            setVarsForPeer $org $peer

            peer channel join -b $channels_folder/${channelName}/${channelName}.block \
                --tls --cafile $ORDERER_CA
            echo "Wait join..."
            sleep 1

            if [ "$peer" == "0" ]; then # see configtx.yaml, AnchorPeers
                peer channel update -o orderer.jincor.com:7050 -c ${channelName} -f $channels_folder/${channelName}/${orgsMspIds[$org]}Anchors.tx \
                    --tls --cafile $ORDERER_CA
                echo "Wait update..."
                sleep 1
            fi
        done
    done
}

createChannel org1 common
joinAndUpdatePeer common "org1 org2" "0 1"

createChannel org1 org1
joinAndUpdatePeer org1 "org1" "0 1"
createChannel org2 org2
joinAndUpdatePeer org2 "org2" "0 1"
createChannel org3 org3
joinAndUpdatePeer org3 "org3" "0 1"

echo 'Done!'
