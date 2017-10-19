#!/bin/bash

git clone https://github.com/hyperledger/blockchain-explorer.git ../blockchain-explorer

docker run --rm -ti \
    --mount type=bind,source="$(pwd)"/../blockchain-explorer,target=/blockchain-explorer \
    -w /blockchain-explorer \
    node:8.7-alpine sh -c "apk update; apk add python make g++; su -c 'npm install' node"

# quick and dirty
sed -i -r 's/users\[0\].secret/"pq5r9doJbINkRcMHOrKAo7AvYDE"/' ../blockchain-explorer/app/helper.js
sed -i -r 's/users\[0\].username/"Admin@ca.network.jincor.com"/' ../blockchain-explorer/app/helper.js

cp -vf ./network-config*.json ../blockchain-explorer/app/
cp -vf ./config.json ../blockchain-explorer/config.json
