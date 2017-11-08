#!/bin/bash

set -ex

export FABRIC_CFG_PATH=${PWD}

source ../../scripts/shared/cert-tools.sh

function buildCommonMsp() {
  fca=$1
  workPath=$2
  mkdir -p "$workPath/"{ca,msp,tlsca,users} "$workPath/msp/"{admincerts,cacerts,tlscacerts}

  cp -vf ./fabric-ca/$fca/ca-cert.pem $workPath/ca/ca-cert.pem
  cp -vf ./fabric-ca/$fca/tlsca-cert.pem $workPath/tlsca/tlsca-cert.pem
  cp -vf ./fabric-ca/$fca/ca-cert.pem $workPath/msp/cacerts/ca-cert.pem
  cp -vf ./fabric-ca/$fca/tlsca-cert.pem $workPath/msp/tlscacerts/tlsca-cert.pem
}

function buildConcreteMsp() {
  fca=$1
  basePath=$2
  workPath=$3/$4
  name=$4
  mkdir -p "$workPath"/msp/{admincerts,cacerts,keystore,signcerts,tlscacerts} "$workPath/tls"

  cp -vf $basePath/ca/ca-cert.pem $workPath/msp/cacerts/ca-cert.pem
  cp -vf $basePath/tlsca/tlsca-cert.pem $workPath/msp/tlscacerts/tlsca-cert.pem
  cp -vf $basePath/tlsca/tlsca-cert.pem $workPath/tls/ca.crt

  docker exec -ti $fca /bin/bash /etc/hyperledger/fabric-ca-server/fcaclient.sh $name cert enroll

  mv -vf ./fabric-ca/$fca/client/msp/signcerts/*.pem $workPath/msp/signcerts/
  mv -vf ./fabric-ca/$fca/client/msp/keystore/*_sk $workPath/msp/keystore/

  docker exec -ti $fca /bin/bash /etc/hyperledger/fabric-ca-server/fcaclient.sh $name tls enroll

  mv -vf ./fabric-ca/$fca/client/msp/signcerts/*.pem $workPath/tls/server.crt
  mv -vf ./fabric-ca/$fca/client/msp/keystore/*_sk $workPath/tls/server.key
}

function initConfigsFca() {
  echo "----------------------- Initialize configuration --------------------------------"
  mkdir -p channels/orderer crypto-config fabric-ca/ca.orderer.jincor.com/msp/keystore fabric-ca/ca.network.jincor.com/msp/keystore

  echo ">> Make orderer CA/TLS certs..."
  makeCa ./fabric-ca/ca.orderer.jincor.com/ca-cert /O=Jincor/CN=ca.orderer.jincor.com
  cp ./fabric-ca/ca.orderer.jincor.com/ca-cert.key ./fabric-ca/ca.orderer.jincor.com/msp/keystore/ca-key.pem
  cp ./fabric-ca/ca.orderer.jincor.com/ca-cert.pem ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem
  mv ./fabric-ca/ca.orderer.jincor.com/ca-cert.key ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem

  makeCert ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsserver-cert /CN=ca.orderer.jincor.com
  makeCert ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsca-cert.pem ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.orderer.jincor.com/tlsclient /CN=tls.client.ca.orderer.jincor.com
  mv ./fabric-ca/ca.orderer.jincor.com/tlsserver-cert.key ./fabric-ca/ca.orderer.jincor.com/msp/keystore/tlsserver-key.pem

  echo ">> Make network CA/TLS certs..."
  makeCa ./fabric-ca/ca.network.jincor.com/ca-cert /O=Jincor/CN=ca.network.jincor.com
  cp ./fabric-ca/ca.network.jincor.com/ca-cert.key ./fabric-ca/ca.network.jincor.com/msp/keystore/ca-key.pem
  cp ./fabric-ca/ca.network.jincor.com/ca-cert.pem ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem
  mv ./fabric-ca/ca.network.jincor.com/ca-cert.key ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem

  makeCert ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.network.jincor.com/tlsserver-cert /CN=ca.network.jincor.com
  makeCert ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem \
    ./fabric-ca/ca.network.jincor.com/tlsca-cert.pem ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsca-key.pem \
    ./fabric-ca/ca.network.jincor.com/tlsclient /CN=tls.client.ca.network.jincor.com
  mv ./fabric-ca/ca.network.jincor.com/tlsserver-cert.key ./fabric-ca/ca.network.jincor.com/msp/keystore/tlsserver-key.pem

  echo ">> Start CA's..."
  docker run -d --name ca.orderer.jincor.com -h ca.orderer.jincor.com -v ${PWD}/fabric-ca/ca.orderer.jincor.com:/etc/hyperledger/fabric-ca-server jincort/hlf-ca:x86_64-1.1.0
  docker run -d --name ca.network.jincor.com -h ca.network.jincor.com -v ${PWD}/fabric-ca/ca.network.jincor.com:/etc/hyperledger/fabric-ca-server jincort/hlf-ca:x86_64-1.1.0
  echo ">> Wait 360 sec..."
  sleep 360

  echo ">> Make orderer msp..."
  fca="ca.orderer.jincor.com"
  currentPath="./crypto-config/ordererOrganizations/orderer.jincor.com"
  buildCommonMsp "$fca" "$currentPath"

  echo ">> Make orderer Admin msp..."
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/users" "Admin@orderer.jincor.com"
  cp -vf $currentPath/users/Admin@orderer.jincor.com/msp/signcerts/*.pem $currentPath/users/Admin@orderer.jincor.com/msp/admincerts
  cp -vf $currentPath/users/Admin@orderer.jincor.com/msp/signcerts/*.pem $currentPath/msp/admincerts

  echo ">> Make orderer Nodes msp..."
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/orderers" "orderer0.orderer.jincor.com"
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/orderers" "orderer1.orderer.jincor.com"
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/orderers" "orderer2.orderer.jincor.com"
  cp -vf $currentPath/users/Admin@orderer.jincor.com/msp/signcerts/*.pem $currentPath/orderers/orderer0.orderer.jincor.com/msp/admincerts/
  cp -vf $currentPath/users/Admin@orderer.jincor.com/msp/signcerts/*.pem $currentPath/orderers/orderer1.orderer.jincor.com/msp/admincerts/
  cp -vf $currentPath/users/Admin@orderer.jincor.com/msp/signcerts/*.pem $currentPath/orderers/orderer2.orderer.jincor.com/msp/admincerts/

  echo ">> Make network msp..."
  fca="ca.network.jincor.com"
  currentPath="./crypto-config/peerOrganizations/network.jincor.com"
  buildCommonMsp "$fca" "$currentPath"

  echo ">> Make network Admin msp..."
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/users" "Admin@network.jincor.com"
  cp -vf $currentPath/users/Admin@network.jincor.com/msp/signcerts/*.pem $currentPath/users/Admin@network.jincor.com/msp/admincerts
  cp -vf $currentPath/users/Admin@network.jincor.com/msp/signcerts/*.pem $currentPath/msp/admincerts

  echo ">> Make network Nodes msp..."
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/peers" "peer0.network.jincor.com"
  buildConcreteMsp "$fca" "$currentPath" "$currentPath/peers" "peer1.network.jincor.com"
  cp -vf $currentPath/users/Admin@network.jincor.com/msp/signcerts/*.pem $currentPath/peers/peer0.network.jincor.com/msp/admincerts/
  cp -vf $currentPath/users/Admin@network.jincor.com/msp/signcerts/*.pem $currentPath/peers/peer1.network.jincor.com/msp/admincerts/

  echo ">> Stopping and removing CA's containers..."
  docker stop ca.orderer.jincor.com ca.network.jincor.com
  docker rm ca.orderer.jincor.com ca.network.jincor.com

  makeGenesisAndChannel

  echo "----------------------- Configuration is ready! ---------------------------------"
}


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

  makeGenesisAndChannel

  echo "----------------------- Configuration is ready! ---------------------------------"
}

function makeGenesisAndChannel() {
  echo ">> Make orderer genesis block"
  ../../scripts/tools/bin/configtxgen -profile JincorOrdererGenesis -channelID=jincormetaorderer \
    -outputBlock ./channels/orderer/orderer.genesis.block

  echo ">> Make channel jincornetwok"
  ../../scripts/tools/bin/configtxgen -profile JincorNetworkChannel \
    -outputCreateChannelTx ./channels/JincorNetworkChannel.tx -channelID=jincormetanet

  echo ">> Make anchors for jincornetwork"
  ../../scripts/tools/bin/configtxgen -profile JincorNetworkChannel \
    -outputAnchorPeersUpdate ./channels/JincorNetworkChannelAnchors.tx -channelID=jincormetanet -asOrg JincorNetwork
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
  local channelName="jincormetanet"

  execCliContainer "peer0.network.jincor.com" channel create -c $channelName -f $configDir/JincorNetworkChannel.tx $orderer
  execCliContainer "peer0.network.jincor.com" channel fetch -c $channelName $orderer config $configDir/JincorNetworkChannel.block

  for peer in peer0 peer1; do
    execCliContainer "$peer.network.jincor.com" channel join -b $configDir/JincorNetworkChannel.block $orderer
  done

  execCliContainer "peer0.network.jincor.com" channel update -c $channelName -f $configDir/JincorNetworkChannelAnchors.tx $orderer

  echo "----------------------- jincormetanet is ready! ---------------------------------"
}

case "$1" in

  config)
    initConfigsFca
    mkdir -p ../devops/shared/
    cp -rvf ./crypto-config/ordererOrganizations/orderer.jincor.com/orderers ../devops/shared/
    cp -rvf ./crypto-config/peerOrganizations/network.jincor.com/peers ../devops/shared/
    cp -rvf ./channels/ ../devops/shared/
    cp -rvf ./fabric-ca/ ../devops/shared/
    cp -rvf ./crypto-config/ordererOrganizations/orderer.jincor.com/msp/tlscacerts ../devops/shared/orderers/
    cp -rvf ./crypto-config/peerOrganizations/network.jincor.com/msp/tlscacerts ../devops/shared/peers/
    ;;
  jincornetwork)
    initJincorNetworkChannel
    ;;
  *)
    echo "Usage: init.sh {config|jincornetwork}"
    ;;

esac
