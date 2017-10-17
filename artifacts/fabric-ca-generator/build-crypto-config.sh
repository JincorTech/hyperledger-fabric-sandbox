#!/bin/bash

[ ! -e bin/fabric-ca-client ] && echo "No file bin/fabric-ca-client" && exit
[ -z "$(ps f | grep fabric-ca-server | grep -v grep)" ] && echo "You should start fabric-ca-server first!" && exit

# Make base folders
mkdir -p ../crypto-config/ordererOrganizations/jincor.com/{ca,msp,orderers,tlsca,users}
mkdir -p ../crypto-config/peerOrganizations/org{1,2,3}.jincor.com/{ca,msp,peers,tlsca,users}

function fcl() {
    home=$1
    cmd=$2
    shift
    shift
    ./bin/fabric-ca-client $cmd -H=${PWD}/../crypto-config/$home -d -m=$home $@
}

function fcluc() {
    home=$1
    cred=$2
    cmd=$3
    shift
    shift
    shift
    fcl $home $cmd -u http://$cred@localhost:6054 $@
}

function fclu() {
    home=$1
    cmd=$2
    shift
    shift
    fcl $home $cmd -u http://localhost:6054 $@
}

function baseOrdererInit() {
  wdir="../crypto-config/ordererOrganizations/jincor.com"

  fcluc ordererOrganizations/jincor.com admin:adminpw getcacert --caname=ca.jincor.com
  for org in org1 org2 org3; do
      fcluc peerOrganizations/$org.jincor.com admin:adminpw getcacert --caname=ca.$org.jincor.com
  done

  fcluc ordererOrganizations/jincor.com/users admin:adminpw enroll --caname=ca.jincor.com -M Admin@jincor.com/msp \
    --id.name=OrdererAdmin --id.type=orderer \
    --csr.cn=OrdererAdmin --csr.hosts=orderer.jincor.com --csr.names=OU=,O=orderer.jincor.com,C=US,ST=NorthCarolina,L=SanFrancisco

  mkdir -p $wdir/orderers/orderer.jincor.com/{msp,tls}
  cp -fvr $wdir/users/Admin@jincor.com/msp/ $wdir/orderers/orderer.jincor.com/
  cp -fvr $wdir/orderers/orderer.jincor.com/msp/signcerts $wdir/orderers/orderer.jincor.com/msp/admincerts
  cp -vf $wdir/msp/tlscacerts/* $wdir/orderers/orderer.jincor.com/tls/ca.crt
  cp -fv $wdir/users/Admin@jincor.com/msp/signcerts/* $wdir/orderers/orderer.jincor.com/tls/server.crt
  cp -fv $wdir/users/Admin@jincor.com/msp/keystore/* $wdir/orderers/orderer.jincor.com/tls/server.key
  cp -frv $wdir/orderers/orderer.jincor.com/msp $wdir
}

function basePeersInit() {
  for org in org1 org2 org3; do
    fcluc peerOrganizations/$org.jincor.com/users admin:adminpw enroll --caname=ca.$org.jincor.com -M Admin@$org.jincor.com/msp \
      --id.affiliation=$org --id.name=PeerAdmin --id.type=peer \
      --csr.cn=PeerAdmin --csr.hosts=$org.jincor.com --csr.names=OU=,O=$org.jincor.com,C=US,ST=NorthCarolina,L=SanFrancisco

    wdir="../crypto-config/peerOrganizations/$org.jincor.com"
    mkdir -p $wdir/peers/peer{0,1}.$org.jincor.com/{msp,tls}
    for peer in peer0 peer1; do
      cp -vfr $wdir/users/Admin@$org.jincor.com/msp/ $wdir/peers/$peer.$org.jincor.com/
      cp -vfr $wdir/users/Admin@$org.jincor.com/msp/signcerts $wdir/peers/$peer.$org.jincor.com/msp/admincerts
      cp -vf $wdir/msp/tlscacerts/* $wdir/peers/$peer.$org.jincor.com/tls/ca.crt
      cp -fv $wdir/users/Admin@$org.jincor.com/msp/signcerts/* $wdir/peers/$peer.$org.jincor.com/tls/server.crt
      cp -fv $wdir/users/Admin@$org.jincor.com/msp/keystore/* $wdir/peers/$peer.$org.jincor.com/tls/server.key
      cp -vfr $wdir/peers/$peer.$org.jincor.com/msp $wdir
    done
  done

  for username in User1 User2; do
   for org in org1 org2 org3; do
    fclu peerOrganizations/$org.jincor.com/users register --caname=ca.$org.jincor.com -M Admin@$org.jincor.com/msp \
      --id.secret userpw \
      --id.affiliation=$org --id.name=$username --id.type=user --id.attrs='"hf.Registrar.Roles=user","hf.Revoker=true"' \
      --csr.cn=$username --csr.hosts=$org.jincor.com --csr.names=OU=,O=$org.jincor.com,C=US,ST=NorthCarolina,L=SanFrancisco

    fcluc peerOrganizations/$org.jincor.com/users $username:userpw enroll --caname=ca.$org.jincor.com -M $username@$org.jincor.com/msp \
      --id.affiliation=$org --id.name=$username --id.type=user \
      --csr.cn=$username --csr.hosts=$org.jincor.com --csr.names=OU=,O=$org.jincor.com,C=US,ST=NorthCarolina,L=SanFrancisco
   done
  done
}

baseOrdererInit
basePeersInit
