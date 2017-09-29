# Sandbox for Hyperledger Fabric


## Pre-requisites

1. docker
1. docker-compose
1. bash

*Preferred Linux environment*.


## Installation

Go to the `scripts` and launch `./init.sh`. Magic includes: Install fabric tools, fetch docker images, make msp & fabric blocks & fabric channels, join channels to peer and anchor them, build and install sample chaincodes. That's all.


## Fabric containers controlling

To controll the containers, use: `scripts/containers-control.sh {ARGS}`, where *ARGS* are: up, down, stop, start, redeploy (down,up)


## Chaincodes

Look at folder `chaincode/github.com/JincorTech`.

* `make.sh` to build a chaincode
* `install.sh` to install a chaincode
* `run.sh` to run a chaincode in dev/debug mode
* `interact.sh` to interact with a chaincode (init,invoke,query)

All this commands should be launch in docker cli.jincor.com container.


## Join Organization to channels

Look at `artifacts/add-org.sh`.
To join Org3 to `org1` and `org2` channels use `./add-org.sh org3 Org3MSP org1 org1; ./add-org.sh org3 Org3MSP org2 org2`
