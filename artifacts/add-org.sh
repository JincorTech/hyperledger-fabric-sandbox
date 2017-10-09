#!/usr/bin/env /bin/bash

[ -z $(which jq) ] && echo 'Install jq first!' && exit
[ -z "$1" ] && echo 'Specify src org' && exit
[ -z "$2" ] && echo 'Specify src orgmsp' && exit
[ -z "$3" ] && echo 'Specify channel' && exit
[ -z "$4" ] && echo 'Specify orgsOwnerOfChannel' && exit

org=$1
orgMsp=$2
channel=$3
owners=$4

echo 'Update membership...'

cd $(dirname $0)

pwd=$PWD

function die(){
    echo ERROR: $1 && exit
}

tmpFolder="tmp"
configtxlatorcmd="curl -X POST http://127.0.0.1:7059"

function prepareEnvironment(){
    mkdir -p $tmpFolder
    cd $tmpFolder
    rm -rf ../$tmpFolder/*
}

function prepareChannelBlock(){
    prepareEnvironment

    channelBlockPath=$1

    sleep 0.5

    $configtxlatorcmd/protolator/decode/common.Block --data-binary @$channelBlockPath > block.json || die "Can't decode block"

    cat block.json | jq .data.data[0].payload.data.config > config.json
}

function buildUpdateChannelBlock(){
    locChannel=$1
    $configtxlatorcmd/protolator/encode/common.Config --data-binary @config.json > config.pb || die "Can't encode"
    $configtxlatorcmd/protolator/encode/common.Config --data-binary @config_new.json > config_new.pb || die "Can't encode updated json"
    $configtxlatorcmd/configtxlator/compute/update-from-configs \
        -F channel=$locChannel -F original=@config.pb -F updated=@config_new.pb > config_updates.pb || die "Can't get updation"
    $configtxlatorcmd/protolator/decode/common.ConfigUpdate --data-binary @config_updates.pb > config_updates.json || die "Can't decode updates"

    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$locChannel'", "type":2}},"data":{"config_update":'$(cat config_updates.json)'}}}' | \
        jq . > config_updates_envelope.json

    $configtxlatorcmd/protolator/encode/common.Envelope --data-binary @config_updates_envelope.json \
        > config_updates_envelope.pb || die "Can't wrap envelope"

    cd ..
}

function prepareGenesisBlock(){
    genesisBlockPath=$1
    prepareEnvironment
    $configtxlatorcmd/protolator/decode/common.Block --data-binary @$genesisBlockPath > block.json || die "Can't decode block"
}


function buildGenesisBlock(){
    $configtxlatorcmd/protolator/encode/common.Block --data-binary @block_new.json > block_new.pb || die "Can't encode"
    cd ..
}


function updateGenesisBlock(){
    echo "Update orderer gensis block..."

    ../scripts/containers-control.sh exec cli.jincor.com bash /opt/sandbox/scripts/shared/exec-peer.sh orderer 0 \
        channel fetch config /opt/sandbox/artifacts/channels/base_genesis.block -c testchainid

    prepareChannelBlock ../channels/base_genesis.block

    certsPath="../crypto-config/peerOrganizations/$org.jincor.com/msp"
    configPath=".channel_group.groups.Consortiums.groups.CommonConsortium.groups.$orgMsp.values.MSP.value.config"

    jsonPart=$(cat config.json | jq '.channel_group.groups.Consortiums.groups.CommonConsortium.groups.Org1MSP' |
      jq '(.. | select(objects | has("n_out_of"))).n_out_of.n = 0' |
      sed "s/Org1MSP/$orgMsp/g")

    jq ".channel_group.groups.Consortiums.groups.CommonConsortium.groups.$orgMsp = $jsonPart" < config.json |
        jq "$configPath.admins[0] = \"$(base64 < $certsPath/admincerts/Admin@$org.jincor.com-cert.pem)\"" |
        jq "$configPath.root_certs[0] = \"$(base64 < $certsPath/cacerts/ca.$org.jincor.com-cert.pem)\"" |
        jq "$configPath.tls_root_certs[0] = \"$(base64 < $certsPath/tlscacerts/tlsca.$org.jincor.com-cert.pem)\"" > config_new.json

    buildUpdateChannelBlock testchainid

    ../scripts/containers-control.sh exec cli.jincor.com bash /opt/sandbox/scripts/shared/exec-peer.sh orderer 0 \
        channel update -f /opt/sandbox/artifacts/tmp/config_updates_envelope.pb -c testchainid
}


function updateChannelBlock(){
    echo "Update application channel block..."

    firstOrg=$(echo $owners | cut -d\  -f 1)

    ../scripts/containers-control.sh exec cli.jincor.com bash /opt/sandbox/scripts/shared/exec-peer.sh $firstOrg 0 \
        channel fetch config /opt/sandbox/artifacts/channels/$channel.block -c $channel

    prepareChannelBlock ../channels/$channel.block

    certsPath="../crypto-config/peerOrganizations/$org.jincor.com/msp"
    configPath=".channel_group.groups.Application.groups.$orgMsp.values.MSP.value.config"

    templateOrg=${firstOrg^}MSP

    jsonPart=$(cat config.json | jq '.channel_group.groups.Application.groups.'$templateOrg | sed "s/$templateOrg/$orgMsp/g")

    jq ".channel_group.groups.Application.groups.$orgMsp = $jsonPart" < config.json |
        jq "$configPath.admins[0] = \"$(base64 < $certsPath/admincerts/Admin@$org.jincor.com-cert.pem)\"" |
        jq "$configPath.root_certs[0] = \"$(base64 < $certsPath/cacerts/ca.$org.jincor.com-cert.pem)\"" |
        jq "$configPath.tls_root_certs[0] = \"$(base64 < $certsPath/tlscacerts/tlsca.$org.jincor.com-cert.pem)\"" > config_new.json

    buildUpdateChannelBlock $channel

    for org in $owners; do
        if [ "$org" = "$firstOrg" ]; then continue; fi
        ../scripts/containers-control.sh exec cli.jincor.com bash /opt/sandbox/scripts/shared/exec-peer.sh $org 0 \
            channel signconfigtx -f /opt/sandbox/artifacts/tmp/config_updates_envelope.pb
    done

    ../scripts/containers-control.sh exec cli.jincor.com bash /opt/sandbox/scripts/shared/exec-peer.sh $firstOrg 0 \
        channel update -f /opt/sandbox/artifacts/tmp/config_updates_envelope.pb -c $channel
}

../scripts/tools/bin/configtxlator start &
sleep 0.5

if [ "$channel" = "testchainid" ]; then
    updateGenesisBlock
else
    updateChannelBlock
fi

killall configtxlator

echo 'Done!'
