#!/bin/bash

[ "$1" == "del" ] && rm -rf ./storage/{,org1.,org2.,org3.}jincor.com/{msp,*.pem,*.crt,*.key,fabric-ca-server.db}

. ./ca-tools.sh

if [ "$1" == "del" ]; then
  for org in jincor.com org1.jincor.com org2.jincor.com org3.jincor.com; do
    makeCa ./storage/$org tls-ca tls-ca.$org
    enrollCert ./storage/$org ./storage/$org/tls-server ca.$org
    enrollCert ./storage/$org ./storage/$org/tls-client ca.$org
  done
fi

bash ../../scripts/containers-control.sh up ca.jincor.com
# ca.org1.jincor.com ca.org2.jincor.com ca.org3.jincor.com
