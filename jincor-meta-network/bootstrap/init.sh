#!/bin/bash

export FABRIC_CFG_PATH=${PWD}

source ../../scripts/shared/cert-tools.sh

function initConfigs() {
  echo "----------------------- Initialize configuration --------------------------------"
  mkdir -p channels/orderer crypto-config fabric-ca/ca.orderer.jincor.com/msp/keystore fabric-ca/ca.network.jincor.com/msp/keystore

  echo '>> Make CA and certs by cryptogen'
  ../../scripts/tools/bin/cryptogen generate --config cryptogen.yaml --output=${PWD}/crypto-config

  echo ">> Make orderer genesis block"
  ../../scripts/tools/bin/configtxgen -profile JincorOrdererGenesis -channelID=jincormetaorderer \
    -outputBlock ./channels/orderer/orderer.genesis.block

  echo ">> Make channel jincornetwok"
  ../../scripts/tools/bin/configtxgen -profile JincorNetworkChannel \
    -outputCreateChannelTx ./channels/JincorNetworkChannel.tx -channelID=jincormetanet

  echo ">> Make anchors for jincornetwork"
  ../../scripts/tools/bin/configtxgen -profile JincorNetworkChannel \
    -outputAnchorPeersUpdate ./channels/JincorNetworkChannelAnchors.tx -channelID=jincormetanet -asOrg JincorNetwork

  echo ">> Copy keys & certs to Fabric-CA folders"
  # for JincorOrderer
  cp -vf crypto-config/ordererOrganizations/orderer.jincor.com/ca/*.pem ./fabric-ca/ca.orderer.jincor.com/ca-cert.pem
  cp -vf crypto-config/ordererOrganizations/orderer.jincor.com/ca/*_sk ./fabric-ca/ca.orderer.jincor.com/msp/keystore/ca-key.pem

  cp -vf crypto-config/ordererOrganizations/orderer.jincor.com/tlsca/*.pem ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem
  cp -vf crypto-config/ordererOrganizations/orderer.jincor.com/tlsca/*_sk ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem

  makeCert ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsserver-cert /CN=ca.orderer.jincor.com
  makeCert ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsclient /CN=tls.client.ca.orderer.jincor.com
  mv ./fabric-ca/ca.orderer.jincor.com/tlsserver-cert.key ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsserver-key.pem

  # for JincorNetwork
  cp -vf crypto-config/peerOrganizations/network.jincor.com/ca/*.pem ./fabric-ca/ca.network.jincor.com/ca-cert.pem
  cp -vf crypto-config/peerOrganizations/network.jincor.com/ca/*_sk ./fabric-ca/ca.network.jincor.com/msp/keystore/ca-key.pem

  cp -vf crypto-config/peerOrganizations/network.jincor.com/tlsca/*.pem ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem
  cp -vf crypto-config/peerOrganizations/network.jincor.com/tlsca/*_sk ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem

  makeCert ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.network.jincor.com/tlsserver-cert /CN=ca.network.jincor.com
  makeCert ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.network.jincor.com/tlsclient /CN=tls.client.ca.network.jincor.com
  mv ./fabric-ca/ca.network.jincor.com/tlsserver-cert.key ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsserver-key.pem

  echo "----------------------- Configuration is ready! ---------------------------------"
}

function execCliContainer() {
  peerHost=$1
  shift
  docker-compose -p jincormeta -f ../devops/docker-compose.yaml exec cli.jincor.com sh /opt/sandbox/jincor-cli-exec.sh $peerHost $@
}

function initJincorNetworkChannel() {
  echo "----------------------- Initialize jincormetanet --------------------------------"

  local orderer="-o orderer0.orderer.jincor.com:7050"
  local configDir="/opt/sandbox/channels"

  execCliContainer "peer0.network.jincor.com" channel create -c jincormetanet -f $configDir/JincorNetworkChannel.tx $orderer
  execCliContainer "peer0.network.jincor.com" channel fetch -c jincormetanet  $orderer config $configDir/JincorNetworkChannel.block

  for peer in peer0 peer1; do
    execCliContainer "$peer.network.jincor.com" channel join -b $configDir/JincorNetworkChannel.block $orderer
  done

  execCliContainer "peer0.network.jincor.com" channel update -c jincormetanet -f $configDir/JincorNetworkChannelAnchors.tx $orderer

  echo "----------------------- jincormetanet is ready! ---------------------------------"
}

if [ "$1" == "config" ]; then
  initConfigs
elif [ "$1" == "jincornetwork" ]; then
  initJincorNetworkChannel
else
  echo "Usage: init.sh {config|jincornetwork}"
fi
