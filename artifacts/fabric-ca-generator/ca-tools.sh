#!/bin/bash

subject="/C=US/ST=North Carolina/L=San Francisco"

function makeCa() {
  cafolder=$1
  caprefix=$2
  cn=$3

  openssl ecparam -genkey -name prime256v1 | tail -n -5 > $cafolder/$caprefix.key
  openssl req -new -sha256 -key $cafolder/$caprefix.key -out $cafolder/$caprefix.csr \
    -subj "$subject/O=jincor.com/CN=$cn"
  openssl req -x509 -sha256 -days 3650 -key $cafolder/$caprefix.key -in $cafolder/$caprefix.csr -out $cafolder/$caprefix.crt

  rm $cafolder/$caprefix.csr
}

function enrollCert() {
  cafolder=$1
  certprefix=$2
  cn=$3

  openssl req -newkey ec:$cafolder/tls-ca.crt -nodes -new \
    -subj "$subject/O=jincor.com/CN=$cn" \
    -keyout $certprefix.key -days 3650 -out $certprefix.csr

  openssl x509 -req -days 3650 \
    -CA $cafolder/tls-ca.crt \
    -CAkey $cafolder/tls-ca.key \
    -in $certprefix.csr \
    -set_serial $(python -c "import random;print(int(random.random()*1e10))") \
    -out $certprefix.crt

  rm $certprefix.csr
}
