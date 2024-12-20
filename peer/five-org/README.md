# Test commands for Peer

# Core YAML picked from the following location
setup/config/five-org/core.0/core.yaml

#1 Terminal-1     Launch the Orderer
# PS: Setup the orderer before proceeding
orderer/five-org
>  ./clean.sh all
>  ./init.sh all
>  ./launch.sh

To experiment with recreation of the channel. Simply re-initialize
the orderer and launch.

# Scripts
peer/five-org
./clean.sh              Cleans up the ledger
./clean.sh  all         Cleans up the ledger and other network artefacts

# MUST execute this before executing commands in the terminal
.  env.sh               Sets the environment variables - always use with . as prefix
./show-env.sh           Shows the current environment setup for the peer

#
./init.sh               Initializes the peer setup - creates the channel
                        If the script is executed again it will fail as the channel already exists
                        Similarly if "peer channel create .." command is executed it will fail for the same reason


#2 Terminal-2   Start the Peer
> .  env.sh
> peer node start

This is where we will check the log messages emitted by peer binary

#3 Terminal-3
> .  env.sh

This is where we will execute the commands

========================================================================
Create the channel using the channel transaction created earlier
========================================================================
# NOTE: If you have already executed the ./init.sh it will create the channel
    After that executing the "peer channel create" command will lead to an error
    That will indicate that channel v0 already exist

# Orderer MUST be running for this command
> peer channel create -o localhost:7050 -c acmechannel -f $CONFIG_DIRECTORY/acme-channel.tx
This will generate the acmechannel.block

Launch Peer
==========
> peer node start

Join the channel
================
> peer channel join -o localhost:7050 -b ./acmechannel.block

List the channels
=================
> peer channel list

fetch
=====
 peer channel fetch 0 acmechannel.block -c acmechannel -o localhost:7050


package
=======

# we will store all package under the $HOME/packages
mkdir -p $HOME/packages
CC_LABEL=gocc.1.0-1.0
CC_PACKAGE_FILE=$HOME/packages/$CC_LABEL.tar.gz

 peer lifecycle chaincode package -h

 peer lifecycle chaincode package  $CC_PACKAGE_FILE -p chaincode_example02 --label $CC_LABEL

install
=======
# Ensure that Peer is up & environment & env vars used in package step are set
peer lifecycle chaincode install  -h
peer lifecycle chaincode install  $CC_PACKAGE_FILE

# Tar file is written to the filesystem
echo $CORE_PEER_FILESYSTEMPATH
ls $CORE_PEER_FILESYSTEMPATH/lifecycle/chaincodes/

# Check the installed chaincode
peer lifecycle chaincode queryinstalled

=====================
Approve and Commit
=====================
# Init the Orderer
cd orderer/five-org
./init.sh all
./launch.sh

# Init the peer
cd orderer/five-org
./init.sh all
./launch-package-install.sh     # Launches the peer in background then packages & installs

# Approve for my org
1. Get the package ID
peer lifecycle chaincode queryinstalled

CC_PACKAGE_ID=gocc.1.0-1.0:73b84f18fe3e6cb46ecc8b26aec451db905cd86dbea849542c286b1541693b3c  <<Paste the package ID>>

2. Approve the chaincode
peer lifecycle chaincode approveformyorg -n gocc -v 1.0 -C  acmechannel --sequence 1  --init-required --package-id $CC_PACKAGE_ID

3. Check Commit Readiness
peer   lifecycle   chaincode   checkcommitreadiness -n gocc -v 1.0 -C  acmechannel --sequence 1 --init-required

4. Commit the chaincode
peer lifecycle chaincode commit -n gocc -v 1.0 -C acmechannel --sequence 1 --init-required

5. Check committed
peer lifecycle chaincode querycommitted -n gocc  -C acmechannel

=====================
Init, Query & Invoke
=====================

# Make sure that sample chaincode is committed
# Refer to the commands above

# Ensure that env is setup in the terminal
. env.sh

1. Init the chaincode
peer chaincode invoke --isInit  -n gocc -C acmechannel -c '{"Args":["init","a","100","b","200"]}'

2. Query the chaincode
peer chaincode query -C acmechannel -n gocc  -c '{"Args":["query","a"]}'

3. Invoke the chaincode
peer chaincode invoke -C acmechannel -n gocc  -c '{"Args":["invoke","a","b","10"]}'

-----------------------------
Update the Chaincode Locally
-----------------------------
# Make sure that you have the chaincode committed at sequence=1
# You may follow the instructions above to setup the environment

# Requires approval
# Does not Require Commit

1. Setup the Label
CC_LABEL=gocc.1.0-2.0

2. Generate the package
peer lifecycle chaincode package $HOME/packages/$CC_LABEL.tar.gz --label $CC_LABEL -p chaincode_example02

3. Install the package
peer lifecycle chaincode install $HOME/packages/$CC_LABEL.tar.gz

4. Get the package ID
peer lifecycle chaincode queryinstalled

CC_PACKAGE_ID=<<Set the package ID>>

6. Approve the new package
# Keep the same sequence number

peer lifecycle chaincode approveformyorg -n gocc -v 1.0 -C  acmechannel --sequence 1  --init-required --package-id $CC_PACKAGE_ID --peerAddresses $CORE_PEER_ADDRESS


-----------------------
Upgrade the Chaincode
-----------------------
1. Set up the Label [name = gocc  version = 2.0   Org specific version = 3.0]
CC_LABEL=gocc.2.0-3.0

2. Generate the package
peer lifecycle chaincode package $HOME/packages/$CC_LABEL.tar.gz --label $CC_LABEL -p chaincode_example02

3. Install the package
peer lifecycle chaincode install $HOME/packages/$CC_LABEL.tar.gz

peer lifecycle chaincode queryinstalled
CC_PACKAGE_ID=<<Get the package ID using queryinstalled>>

4. Approve the chaincode
peer lifecycle chaincode approveformyorg -n gocc -v 1.0 -C  acmechannel --sequence 2  --package-id $CC_PACKAGE_ID --peerAddresses $CORE_PEER_ADDRESS

5. Commit the chaincode
peer lifecycle chaincode commit -n gocc -v 1.0 -C acmechannel --sequence 2 --peerAddresses $CORE_PEER_ADDRESS

6. Check committed
peer lifecycle chaincode querycommitted -n gocc  -C acmechannel



channel signconfigtx & update
=============================
Change directory to orderer/five-org
1. Create the anchor peer update tx

configtxgen -outputAnchorPeersUpdate   Org1Anchors.tx -profile  AcmeChannel -channelID  acmechannel   -asOrg  Org1

cp Org1Anchors.tx ../../peer/five-org

Change directory to peer/five-org

2. Sign the transaction

peer channel signconfigtx -f Org1Anchors.tx

Size changes from 268 bytes to 2027 bytes

3. Submit the transaction

peer channel update -f Org1Anchors.tx -c acmechannel -o localhost:7050

4. Check the Blockchain height - it will be 2

peer channel getinfo -c acmechannel




======================================
Start Peer in Dev Mode & testing
NOTE: Dev mode is broken in Fabric 2.1
======================================
1. Start Peer in Dev mode
startdev.sh

2. Build the example chaincode
go install -tags nopkcs11 chaincode_example02

PS: If you get a warning (Permission denied) ignore it *or* you may delete the $HOME/.cache to get rid of it

3. Setup the environment variable
export CORE_CHAINCODE_ID_NAME=goccdev:1.0
export CORE_CHAINCODE_LOGGING_LEVEL=debug
export CORE_PEER_ADDRESS="localhost:7052"

4. Launch the chaincode
$GOPATH/bin/chaincode_example02

5. Install & Instnatiate the chaincode

peer chaincode install -n goccdev -v 1.0  -p chaincode_example02
peer chaincode instantiate  -n goccdev -v 1.0 -C acmechannel -c '{"Args":["init","a","100","b","200"]}'

6. Invoke and Query

peer chaincode invoke  -C acmechannel -n goccdev  -c '{"Args":["invoke","b","a","5"]}'
peer chaincode query -C acmechannel -n goccdev  -c '{"Args":["query","a"]}'

PS: Observe messages in the Chaincode terminal - you will see log messages generated in the code

Docker Cheatsheet
=================
# Kill all stopped containers
docker rm $(docker ps -a -q)
# Remove all images for dev-devpeer
docker rmi $(docker images --filter=reference='dev-devpeer*' -q)




Fetch the latest Config Block
=============================
1. Create a temp folder under the peer/five-org
2. Fetch the latest config block
> peer channel fetch config -c acmechannel -o localhost:7050 temp/config_block.pb
3. Convert the block file to JSOn format
> configtxlator proto_decode --input ./temp/config_block.pb --type common.Block > ./temp/config_block.json
4. Setup env variable for the config path
> export JQ_CONFIG_PATH=.data.data[0].payload.data.config.channel_group.groups.Orderer.values
5. Print the config information using JQ
> cat ./temp/config_block.json | jq $JQ_CONFIG_PATH



Docker Container CouchDB
========================
Installing a docker container for CouchDB instead of using the native installation

docker run -p 5984:5984 --name couchdb -d couchdb

docker exec -it couchdb /bin/bash


Remote access to Futon
======================
By default CouchDB binds to localhost:5984 as a result it wont be accessible from remote machine
To fix this bind address need to be changed

> sudo vi  /etc/couchdb/local.ini
[httpd]
bind_address=0.0.0.0

[admins]
admin = admin

Restart the CouchDB daemon

--------------------------------------
# Fabric 1.x Sample BELOW THIS - Ignore
--------------------------------------
Removing the Chaincode
======================
1. Checkout the installed & instantiated chaincode
peer chaincode list --installed
peer chaincode list --instantiated -C acmechannel

2. Shutdown the peer

3. Delete the package
cd $CORE_PEER_FILESYSTEMPATH/chaincodes
rm gocc.1.0

4. Stop the container
docker ps | grep dev-devpeer-gocc-1.0
docker rm -f <<Container ID>>

5. (optional)
Run the query - Peer will automatically start the container again
peer chaincode query -C acmechannel -n goccdev  -c '{"Args":["query","a"]}'

Repeat step 4. if you executed this step

6. Remove the image
docker images | grep dev-devpeer-gocc-1.0
docker rmi <<Image ID>>

7. Start the peer
peer chaincode list --installed
peer chaincode list --instantiated -C acmechannel

8. Run the query - this time peer will not launch the container & command will fail
peer chaincode query -C acmechannel -n goccdev  -c '{"Args":["query","a"]}'

9. Re-install & Instantiate the gocc
peer chaincode install -n gocc -v 1.0  -p chaincode_example02
No need to instantiate - running a query will launch the container
# Run some code

Install the test code
=====================
> peer chaincode install -n gocc -v 1.0  -p chaincode_example02

Instantiate the code
====================
> peer chaincode instantiate  -n gocc -v 1.0 -C acmechannel -c '{"Args":["init","a","100","b","200"]}'

Check Status
============
> peer chaincode list  --installed
> peer chaincode list  --instantiated   -C acmechannel

Query & invoke
==============
peer chaincode query -C acmechannel -n gocc  -c '{"Args":["query","a"]}'
peer chaincode invoke -C acmechannel -n gocc  -c '{"Args":["invoke","a","b","10"]}'

Upgrade the code
================
peer chaincode install -n gocc -v 1.0  -p chaincode_example02
peer chaincode upgrade -n gocc -v 1.0  -C acmechannel  -c '{"Args":["init","c","100","d","200"]}'

Package the code
================
peer chaincode package -n gocc -v 2.0 -p chaincode_example02   packageV5.0.out
peer chaincode install packageV5.0.out

Build the Go code
=================

go install  -tags nopkcs11 chaincode_example02



Exercise - Upgrading the chaincode
==================================
1. Initialize & Launch the orderer and the peer
2. Install the example02 nodeJS chaincode to the peer as V 1.0
3. Instantiate the example02JS V 1.0 chaincode with "a"="100", "b"="100"
4. Invoke the chaincode to transfer 10 from "a" to "b"
5. Run the query on "a" to check if transfer was successful
6. Install the example02 nodeJS chaincode to the peer as V 2.0
7. Upgrade the chaincode to V 2.0 with "c"="100", "d"="100"
8. Run the query on "a" - what value do you see for "a"?


Exercise - Add a peer to Org1MSP
================================



Execute Go Chaincode
====================
export FABRIC_CFG_PATH=./      <<Set to the path to core.yaml>>

peer chaincode query -C acmechannel -n gocc  -c '{"Args":["query","a"]}'

peer chaincode query -C acmechannel -n gocc -c '{"Args":["query","a"]}'

peer chaincode invoke -C acmechannel -n gocc  -c '{"Args":["invoke","b","a","5"]}'

peer chaincode query -o localhost:7050 -C acmechannel -n gocc   -c '{"Args":["query","a"]}'

Execute node
============
 peer chaincode install -n nodecc -v 1.0 -l node -p ../../nodechaincode/chaincode_example02
 peer chaincode instantiate -o localhost:7050 -C acmechannel -n nodecc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'
 peer chaincode invoke -C acmechannel -n nodecc  -c '{"Args":["invoke","b","a","5"]}'
 peer chaincode query  -C acmechannel -n nodecc  -c '{"Args":["query","a"]}'

Upgrade
=======
peer chaincode install -n gocc -v 2.0 -l node -p ../../nodechaincode/chaincode_example02
peer chaincode upgrade -C acmechannel -n gocc -v 2.0 -c '{"Args":[]}'
