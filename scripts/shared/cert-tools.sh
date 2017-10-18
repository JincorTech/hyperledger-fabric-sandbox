#!/usr/bin/env /bin/bash

SUBJECT_PREFIX="${SUBJECT_PREFIX:-/C=CY/ST=/L=Larnaca/O=Jincor Limited}"
OPENSSL_CNF="${OPENSSL_CNF:-openssl.cnf}"

SN=$(python -c "import random;print(int(random.random()*1e10)+23827687352719554684093473638517501167421842944L)")

function makeCa() {
  local workPathPrefix=$1
  local subject=$2

  echo "Generate key $workPathPrefix.key"
  openssl genpkey -out "$workPathPrefix.key" -algorithm ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -pkeyopt ec_param_enc:named_curve

  echo "Generate certificate request $workPathPrefix.csr"
  openssl req -new -sha256 \
    -key "$workPathPrefix.key" -out "$workPathPrefix.csr" \
    -subj "$SUBJECT_PREFIX$subject" \
    -reqexts "v3_req"

  echo "Generate certificate $workPathPrefix.crt"
  openssl req -x509 -sha256 \
    -key "$workPathPrefix.key" \
    -in "$workPathPrefix.csr" \
    -out "$workPathPrefix.pem" \
    -set_serial "$SN" \
    -config "$OPENSSL_CNF" \
    -days 3650 \
    -extensions "v3_ca"

  echo "Remove request $workPathPrefix.csr"
  rm "$workPathPrefix.csr"
}

function makeCert() {
  local caCertFile=$1
  local signCertFile=$2
  local signKeyFile=$3
  local workPathPrefix=$4
  local subject=$5

  echo "Generate key and request $workPathPrefix.{key,pem}"
  openssl req -newkey "ec:$caCertFile" -nodes -new -sha256  -days 3650  \
    -reqexts "v3_req" \
    -subj "$SUBJECT_PREFIX$subject" \
    -keyout "$workPathPrefix.key" \
    -out "$workPathPrefix.csr"

  echo "Generate certificate $workPathPrefix.crt"
  openssl x509 -req -days 3650 \
    -extfile "$OPENSSL_CNF" \
    -extensions "v3_req" \
    -CA "$signCertFile" \
    -CAkey "$signKeyFile" \
    -in "$workPathPrefix.csr" \
    -set_serial "$SN" \
    -out "$workPathPrefix.pem"

  echo "Remove request $workPathPrefix.csr"
  rm "$workPathPrefix.csr"
}
