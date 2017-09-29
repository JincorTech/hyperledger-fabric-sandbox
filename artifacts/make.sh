#!/usr/bin/env /bin/bash

cd $(dirname $(type -p $0))

pwd=$PWD

function clean() {
    echo 'Clean folders...'
    rm -rf $pwd/crypto-config/* $pwd/channels/*
    mkdir -p $pwd/crypto-config $pwd/channels/
}


function buildMsp() {
    echo 'Make CA and certs...'
     ../scripts/tools/bin/cryptogen generate --config cryptogen.yaml --output=$pwd/crypto-config
}


function buildChansAndBlocks() {
    export FABRIC_CFG_PATH=$pwd

    declare -A genesisProfiles channelsProfiles anchors
    genesisProfiles=(
        [base]=TwoOrgsOrdererGenesis
    )
    channelsProfiles=(
        [common]=TwoOrgsChannel
        [org1]=Org1Channel
        [org2]=Org2Channel
        [org3]=Org3Channel
    )
    anchors=(
        [common]="Org1MSP Org2MSP"
        [org1]=Org1MSP
        [org2]=Org2MSP
        [org3]=Org3MSP
    )

    echo "Make genesis blocks..."
    for genesis in ${!genesisProfiles[*]}; do

        echo "Make genesis block $genesis..."
        ../scripts/tools/bin/configtxgen -profile ${genesisProfiles[$genesis]} \
            -outputBlock $pwd/channels/$genesis.block

    done

    echo "Make channels..."
    for channel in ${!channelsProfiles[*]}; do

        mkdir -p $pwd/channels/$channel

        echo "Make channel $channel..."
        channelProfile=${channelsProfiles[$channel]}
        ../scripts/tools/bin/configtxgen -profile $channelProfile \
            -outputCreateChannelTx $pwd/channels/$channel/$channel.tx -channelID=$channel

        echo "Make anchors for $channel..."
        channelAnchor=${anchors[$channel]}
        for anchor in $channelAnchor; do
            echo "Make anchor $anchor..."
            ../scripts/tools/bin/configtxgen -profile $channelProfile \
                -outputAnchorPeersUpdate $pwd/channels/$channel/${anchor}Anchors.tx -channelID=$channel -asOrg $anchor
        done

    done
}

function makeEnvFromTemplate() {
    echo 'Make .env from template...'
    cp -f ../devops/.env.template ../devops/.env

    for org in org1 org2 org3; do
        ca=$(ls crypto-config/peerOrganizations/$org.jincor.com/ca -1 | grep _sk)
        tlsca=$(ls crypto-config/peerOrganizations/$org.jincor.com/tlsca -1 | grep _sk)
        sed -i -e 's/${ca_'$org'}/'$ca'/g' -e 's/${tlsca_'$org'}/'$tlsca'/g' ../devops/.env
    done
}

clean
buildMsp
buildChansAndBlocks
makeEnvFromTemplate

echo 'Done!'
