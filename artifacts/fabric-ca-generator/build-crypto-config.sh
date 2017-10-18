#!/bin/bash

[ -z "$1" ] && echo "Specify yes as argument" && exit

cd $(dirname $0)

. ../../scripts/shared/cert-tools.sh

PWD=`pwd`

function fclient() {
    dn=$1
    cmd=$2
    shift 2

    clientSubPath=storage/client/$dn

    localPath=${PWD}/$clientSubPath
    localMspPath=$localPath/msp

    ../../scripts/containers-control.sh exec -u $(id -u) ca.$dn /usr/local/bin/fabric-ca-client $cmd \
      --tls.certfiles=tlsca.pem \
      --tls.client.certfile=tls-client.pem \
      --tls.client.keyfile=tls-client.key \
      -H=/opt/artifacts/fabric-ca-generator/$clientSubPath -d $@
}

function fclientuc() {
    dn=$1
    cred=$2
    cmd=$3
    shift 3

    fclient $dn $cmd -u https://$cred@ca.$dn:7054 $@
}

function fclientu() {
    dn=$1
    cmd=$2
    shift 2

    fclient $dn $cmd -u https://ca.$dn:7054 $@
}

function moveFiles() {
    fromFolder=$1
    toFolder=$2
    mv -vf $(ls -1 $fromFolder | sed -r 's/ ?tls-client.key ?//' | xargs -i echo -n "$fromFolder/{} " ) $toFolder
}

function changeExts() {
    for f in $(ls -1 $1 | grep "$2\$"); do
        mv -vf $1/$f $1/$(basename $f $2)$3
    done
}



function buildMsp() {
   workPath=$1
   nodesFolder=$2
   prefixNodeName=$3
   postfixNodeName=$4
   nodeStartIndex=$5
   nodeEndIndex=$6
   userNames="Admin $7"

   mkdir -p "$workPath/"{ca,msp,tlsca,users}
   mkdir -p "$workPath/msp/"{admincerts,cacerts,tlscacerts}

   fclientuc $postfixNodeName admin:adminpw getcacert --caname=ca.$postfixNodeName
   moveFiles "$localMspPath/cacerts" "$workPath/ca"
   cp "./storage/$postfixNodeName/tlsca.pem" "$workPath/tlsca/"

   for userName in $userNames; do
       userid="$userName@$postfixNodeName"

       cdir="$workPath/users/$userName@$postfixNodeName"
       mkdir -p "$cdir/msp/"{admincerts,cacerts,keystore,signcerts,tlscacerts}
       mkdir -p "$cdir/tls"

       userType="user"
       creds="user:userpw"
       if [ "$userName" == "Admin" ]; then
          userType=$prefixNodeName
          creds="admin:adminpw"
       fi

       fclientuc $postfixNodeName $creds enroll --caname=ca.$postfixNodeName \
        --id.name=$userid --id.type=$userType \
        --csr.cn=$userid --csr.hosts=$postfixNodeName --csr.names=OU=,O=JincorLimited,C=CY,ST=,L=Larnaca

       moveFiles "$localMspPath/keystore" "$cdir/msp/keystore"
       moveFiles "$localMspPath/signcerts" "$cdir/msp/signcerts"
       cp -vfr "$cdir/msp/signcerts/"* "$cdir/msp/admincerts"
       cp -vfr "$workPath/ca/"* "$cdir/msp/cacerts"
       cp -vfr "$workPath/tlsca/"*.pem "$cdir/msp/tlscacerts"
       cp -vfr "$workPath/tlsca/"*.pem "$cdir/tls/ca.pem"

       makeCert "./storage/$postfixNodeName/tlsca.pem" "./storage/$postfixNodeName/tlsca.pem" "./storage/$postfixNodeName/tlsca.key" \
          "$cdir/tls/server" "/CN=$userid"
       changeExts $cdir/tls/ .pem .crt

       if [ "$userName" == "Admin" ]; then
         cp -vfr "$cdir/msp/admincerts" "$workPath/msp"
         cp -vfr "$cdir/msp/tlscacerts" "$workPath/msp"
         cp -vfr "$cdir/msp/cacerts" "$workPath/msp"
       fi
   done

   mkdir -p "$workPath/$nodeFolder"

   for nodeIndex in $(seq $nodeStartIndex $nodeEndIndex); do
       nodeid="$prefixNodeName$nodeIndex.$postfixNodeName"

       if [ "$nodeStartIndex" == "$nodeEndIndex" ]; then
         nodeid="$prefixNodeName.$postfixNodeName"
       fi

       cdir="$workPath/$nodesFolder/$nodeid"
       mkdir -p "$cdir"/msp/{admincerts,cacerts,keystore,signcerts,tlscacerts} "$cdir/tls"

       fclientuc $postfixNodeName $prefixNodeName:${prefixNodeName}pw enroll --caname=ca.$postfixNodeName \
        --id.name=$nodeid --id.type=$prefixNodeName \
        --csr.cn=$nodeid --csr.hosts=$postfixNodeName --csr.names=OU=,O=JincorLimited,C=CY,ST=,L=Larnaca

       moveFiles "$localMspPath/keystore" "$cdir/msp/keystore"
       moveFiles "$localMspPath/signcerts" "$cdir/msp/signcerts"

       cp -vfr "$workPath/users/Admin@$postfixNodeName/msp/signcerts/"* "$cdir/msp/admincerts"
       cp -vfr "$workPath/ca/"* "$cdir/msp/cacerts"
       cp -vfr "$workPath/tlsca/"*.pem "$cdir/msp/tlscacerts"

       cp -vfr "$workPath/tlsca/"*.pem "$cdir/tls/ca.pem"
       makeCert "./storage/$postfixNodeName/tlsca.pem" "./storage/$postfixNodeName/tlsca.pem" "./storage/$postfixNodeName/tlsca.key" \
          "$cdir/tls/server" "/CN=$nodeid"
       changeExts $cdir/tls/ .pem .crt

   done
}

orderersCount="0"
if [ "$JINCOR_NETWORK_TYPE" == "orderers" ]; then
  orderersCount="2"
fi

buildMsp "../crypto-config/ordererOrganizations/jincor.com" "orderers" "orderer" "jincor.com" 0 $orderersCount ""

buildMsp "../crypto-config/peerOrganizations/org1.jincor.com" "peers" "peer" "org1.jincor.com" 0 1 "User1 User2"
buildMsp "../crypto-config/peerOrganizations/org2.jincor.com" "peers" "peer" "org2.jincor.com" 0 1 "User1 User2"
buildMsp "../crypto-config/peerOrganizations/org3.jincor.com" "peers" "peer" "org3.jincor.com" 0 1 "User1 User2"
