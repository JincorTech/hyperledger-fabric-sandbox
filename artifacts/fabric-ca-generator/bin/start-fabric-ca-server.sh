#!/bin/bash

[ ! -e fabric-ca-server ] && echo "No file bin/fabric-ca-server" && exit
[ "$1" == "del" ] && rm -rf ./storage/{,org1.,org2.,org3.}jincor.com/{msp,ca-cert.pem,fabric-ca-server.db}

cd storage/jincor.com

../../fabric-ca-server start -b admin:adminpw -d \
  --cafiles ../org1.jincor.com/fabric-ca-server-config.yaml \
  --cafiles ../org2.jincor.com/fabric-ca-server-config.yaml \
  --cafiles ../org3.jincor.com/fabric-ca-server-config.yaml
