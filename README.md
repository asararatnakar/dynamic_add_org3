# dynamic_add_org3
Using e2e_cli sample adding a new organization, update channel configuration

This is same as **e2e_cli** sample avaiable in fabric repo.

However if you wanted to add a new organization you would need to execute the following steps:

* Generate certs for Org3 (check **crypto-org3.yaml**)
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
* Once the Normal e2e test execution completed with the following command. i
 it also adds new org **Org3** to the Blockchain network
```
./network_setup.sh restart mychannel 1
```




