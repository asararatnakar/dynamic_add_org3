# dynamic_add_org3
Using e2e_cli sample adding a new organization, update channel configuration

This is same as **e2e_cli** sample avaiable in fabric repo.

However if you wanted to add a new organization you would need to execute the following steps:

* Generate certs for Org3 (Already included in **crypto-config.yaml**)
* Calculate the configuration using configtxgen by including the following block in your configtx.yaml (Already included in configtx.yaml)

```
    - &Org3
        # DefaultOrg defines the organization which is used in the sampleconfig
        # of the fabric.git development environment
        Name: Org3MSP

        # ID to load the MSP definition as
        ID: Org3MSP

        MSPDir: crypto-config/peerOrganizations/org3.example.com/msp

        AnchorPeers:
            # AnchorPeers defines the location of peers which can be used
            # for cross org gossip communication.  Note, this value is only
            # encoded in the genesis block in the Application section context
            - Host: peer0.org3.example.com
              Port: 7051
```

**command:**
```
configtxgen -printOrg Org3MSP
```
* Once the e2e test excute with the following command
```
./network_setup.sh restart mychannel 1000000
```

**Ctrl + D**  or   open a new terminal and enter into cli container `docker exec -it cli bash`

Execute the commands available in **commands.sh** to understand what is happening here.

* Added a new organization Org3
* Installed chaincode on peer0 of Org3
* Query on peer0 of Org3 and check for the value **Query Result: 90**




