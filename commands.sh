#!/bin/bash
# Start configtxlator

configtxlator start &

export CONFIGTXLATOR_URL=http://127.0.0.1:7059
export CHANNEL_NAME="mychannel"
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem


peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

# Decode the block to human readable json format

curl -X POST --data-binary @config_block.pb "$CONFIGTXLATOR_URL/protolator/decode/common.Block" | jq . > config_block.json

# Isolating current config

jq .data.data[0].payload.data.config config_block.json > config.json

cp config.json updated_config.json

# TODO: add org3.json to updated_config.json
## TODO: DO this manually for now

# Translating original config to proto

curl -X POST --data-binary @config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > config.pb


# Translating updated config to proto

curl -X POST --data-binary @updated_config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > updated_config.pb


# Computing config update

curl -X POST -F channel=$CHANNEL_NAME -F "original=@config.pb" -F "updated=@updated_config.pb" "${CONFIGTXLATOR_URL}/configtxlator/compute/update-from-configs" > config_update.pb



# Decoding config update

curl -X POST --data-binary @config_update.pb "$CONFIGTXLATOR_URL/protolator/decode/common.ConfigUpdate" | jq . > config_update.json


# Generating config update envelope

echo '{"payload":{"header":{"channel_header":{"channel_id":"'mychannel'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json


# Encoding config update envelope

curl -X POST --data-binary @config_update_in_envelope.json "$CONFIGTXLATOR_URL/protolator/encode/common.Envelope" > config_update_in_envelope.pb

# Sign with org1
peer channel signconfigtx -f config_update_in_envelope.pb

#switch to org2 -- so that org2 will sign the pb before updating the chnanel

export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051

#Sending config update to channel
peer channel update -f config_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem


## Fetch the latest block and join the peer of org3
peer channel fetch config latest_config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

curl -X POST --data-binary @latest_config_block.pb "$CONFIGTXLATOR_URL/protolator/decode/common.Block" | jq . > latest_config_block.json

export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=peer0.org3.example.com:7051

## peer should get the genesis block.
## Else you would see the following error
##Error: proposal failed (err: rpc error: code = Unknown desc = chaincode error (status: 500, message: Cannot create ledger from genesis block, due to Expected block number=0, recived block number=3))

peer channel join -b config_block.pb

peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02

peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'

### An invoke and query should be done to see if the new org is successfully added to the network

