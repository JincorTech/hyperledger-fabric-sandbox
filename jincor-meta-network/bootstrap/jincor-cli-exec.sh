#!/bin/bash

peerHost=$1

export ORDERER_CA=/opt/sandbox/crypto-config/ordererOrganizations/orderer.jincor.com/tlsca/tlsca.orderer.jincor.com-cert.pem
export CORE_PEER_LOCALMSPID=JincorNetwork
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/sandbox/crypto-config/peerOrganizations/network.jincor.com/peers/$peerHost/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/sandbox/crypto-config/peerOrganizations/network.jincor.com/users/Admin@network.jincor.com/msp
export CORE_PEER_ADDRESS=$peerHost:7051

shift

if [ "${CORE_PEER_TLS_ENABLED}" = "true" ]; then
  peer $@ --tls --cafile $ORDERER_CA
else
  peer $@
fi
