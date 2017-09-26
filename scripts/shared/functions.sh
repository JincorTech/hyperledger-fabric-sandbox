#!/usr/bin/env /bin/bash

declare -A orgsMspIds orgPeers

orgs=(org1 org2)

orgsMspIds=(
    [org1]="Org1MSP"
    [org2]="Org2MSP"
)

orgPeers=(
    [org1.0]=peer0.org1.jincor.com
    [org1.1]=peer1.org1.jincor.com
    [org2.0]=peer0.org2.jincor.com
    [org2.1]=peer1.org2.jincor.com
)

function setVarsForPeer(){
    orgId=$1
    peerId=$2
    export CORE_PEER_LOCALMSPID=${orgsMspIds[$orgId]}
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/sandbox/artifacts/crypto-config/peerOrganizations/${orgId}.jincor.com/peers/${orgPeers[$orgId.$peerId]}/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/sandbox/artifacts/crypto-config/peerOrganizations/${orgId}.jincor.com/users/Admin@${orgId}.jincor.com/msp
    export CORE_PEER_ADDRESS=${orgPeers[$orgId.$peerId]}:7051
    export ORDERER_CA=/opt/sandbox/artifacts/crypto-config/ordererOrganizations/jincor.com/orderers/orderer.jincor.com/msp/tlscacerts/tlsca.jincor.com-cert.pem
}
