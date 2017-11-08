#!/bin/bash

set -ex

function makeVolume() {
  name=$1
  cmd=$2
  docker volume create $name

  if [ -n "$cmd" ]; then
    docker run --rm -it \
      --mount type=volume,src=$name,target=/mount \
      alpine $cmd
  fi
}

function makeVolumeFrom() {
  name=$1
  path=$2

  makeVolume $name
  docker run --rm -it \
    --mount type=bind,source="$(pwd)"/shared/$path,target=/copyfrom/copyto,ro \
    --mount type=volume,src=$name,target=/copyto \
    alpine cp -rvf '/copyfrom/copyto/' '/'
}

function makeBaseVolumes() {
  makeVolumeFrom "jincormetanetCaOrderers" "fabric-ca/ca.orderer.jincor.com"
  makeVolumeFrom "jincormetanetCaNetwork" "fabric-ca/ca.network.jincor.com"
  makeVolumeFrom "jincormetanetOrdererGenesis" "channels/orderer"
  makeVolumeFrom "jincormetanetOrdererCryptodata" "orderers"
  makeVolumeFrom "jincormetanetOrdererCryptodataTlsca" "orderers/tlscacerts"
  makeVolumeFrom "jincormetanetNetworkCryptodata" "peers"
  makeVolumeFrom "jincormetanetNetworkCryptodataTlsca" "peers/tlscacerts"
}

function makeBaseDataVolumes() {
  makeVolume "jincormetanetOrdererData0"
  makeVolume "jincormetanetOrdererData1"
  makeVolume "jincormetanetOrdererData2"

  makeVolume "jincormetanetNetworkPeerData0"
  makeVolume "jincormetanetNetworkPeerData1"

  makeVolume "jincormetanetZooData0" "mkdir -p /mount/log /mount/base"
  makeVolume "jincormetanetZooData1" "mkdir -p /mount/log /mount/base"
  makeVolume "jincormetanetZooData2" "mkdir -p /mount/log /mount/base"

  makeVolume "jincormetanetKafkaData0"
  makeVolume "jincormetanetKafkaData1"
  makeVolume "jincormetanetKafkaData2"
  makeVolume "jincormetanetKafkaData3"
}

case "$1" in

  data)
    makeBaseDataVolumes
    ;;
  crypto)
    makeBaseVolumes
    ;;
  all)
    makeBaseDataVolumes
    makeBaseVolumes
    ;;
  *)
    echo "Usage: init.sh {data|crypto|all}"
    ;;

esac
