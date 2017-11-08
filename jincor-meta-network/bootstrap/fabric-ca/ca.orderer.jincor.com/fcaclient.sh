#!/bin/bash

cd $(dirname $0)

name=$1
profile=$2

caPath="/etc/hyperledger/fabric-ca-server"
basePath="$caPath/client"

rm -rf $basePath
mkdir -p $basePath/msp/keystore

shift 2

cd /etc/hyperledger/fabric-ca-server

cp -f tlsca-cert.pem $basePath
cp -f tlsclient.pem $basePath
cp -f tlsclient.key $basePath/msp/keystore

pass=$(cat fabric-ca-server-config.yaml | sed -r -n '/'$name'/ {n;p}' | awk '{printf $2}')
proto="http"
if [ "$TLS_ENABLED" == "true" ]; then
  proto="https"
fi

fabric-ca-client $@ \
  --tls.certfiles=tlsca-cert.pem \
  --tls.client.certfile=tlsclient.pem \
  --tls.client.keyfile=tlsclient.key \
  --enrollment.profile=$profile \
  --csr.names=C=CY,ST=,L=Larnaca,O=Jincor\ Limited,OU=Jincor \
  -m ca.orderer.jincor.com \
  --id.name=$name \
  --csr.cn=$name --csr.hosts=$name \
  -H=$basePath -d -u $proto://$name:$pass@ca.orderer.jincor.com:7054

chmod -R og+xrw $basePath
