#!/bin/bash

[ "$1" == "del" ] && rm -rf ./storage/{,org1.,org2.,org3.}jincor.com/{msp,*.pem,*.crt,*.key,fabric-ca-server.db} ./storage/client/*

. ../../scripts/shared/cert-tools.sh


if [ "$1" == "del" ]; then
  for org in jincor.com org1.jincor.com org2.jincor.com org3.jincor.com; do
    makeCa "./storage/$org/tlsca" "/CN=tlsca.$org"
    makeCert "./storage/$org/tlsca.pem" "./storage/$org/tlsca.pem" "./storage/$org/tlsca.key" "./storage/$org/tls-server" "/CN=ca.$org"

    mkdir -p storage/client/$org/msp/keystore
    cp "./storage/$org/tlsca.pem" "./storage/client/$org/tlsca.pem"
    makeCert "./storage/$org/tlsca.pem" "./storage/$org/tlsca.pem" "./storage/$org/tlsca.key" "./storage/client/$org/tls-client" "/CN=tls-client.ca.$org"
    mv "./storage/client/$org/tls-client.key" "./storage/client/$org/msp/keystore"

    mkdir -p "./storage/$org/msp/keystore"
    mv "./storage/$org/tls-server.key" "./storage/$org/msp/keystore/"
  done
fi

bash ../../scripts/containers-control.sh up ca.jincor.com ca.org1.jincor.com ca.org2.jincor.com ca.org3.jincor.com

echo "Wait 10 seconds for Fabric CAs to create environments"
sleep 10
