# Private Network

Here are the quick-start for setting up a Tron private network using Docker.

A private chain needs at least one fullnode running by [SR](https://tronprotocol.github.io/documentation-en/mechanism-algorithm/sr/) to produces blocks, and any number of fullnodes to synchronize blocks and broadcast transactions.

## Prerequisites

### Minimum Hardware Requirements
- CPU with 8+ cores
- 32GB RAM
- 100GB free storage space


### Docker

Please download and install the latest version of Docker from the official Docker website:
* Docker Installation for [Mac](https://docs.docker.com/docker-for-mac/install/)
* Docker Installation for [Windows](https://docs.docker.com/docker-for-windows/install/)

## Quick-Start Using Docker
Download the files [private_network_quick_start.sh](https://github.com/tronprotocol/tron-deployment/blob/master/private_net/private_network_quick_start.sh) and [docker-compose.yml](https://github.com/tronprotocol/tron-deployment/blob/master/private_net/docker-compose.yml) from GitHub. Place them in the same directory and run the quick start shell script. 
```
chmod +x private_network_quick_start.sh
./private_network_quick_start.sh 
```
The shell script just downloads two configuration files and starts the Docker composer.
A Tron private network will be started with one [SR](https://tronprotocol.github.io/documentation-en/mechanism-algorithm/sr/#super-representative) and a normal FullNode.

Check the witness logs by running below command:
```
docker exec -it tron_witness tail -f ./logs/tron.log
```
Normally, it should show the witness initializing the database and network, then starting to produce blocks every 3 seconds.
```
01:58:06.013 INFO  [DPosMiner] [DB](Manager.java:1546) Generate block 1 begin.
01:58:06.158 INFO  [DPosMiner] [DB](Manager.java:1669) Generate block 1 success, trxs:0, before pendingCount: 0, rePushCount: 0, from pending: 0, rePush: 0, after pendingCount: 0, rePushCount: 0, postponedCount: 0, blockSize: 175 B
01:58:06.162 INFO  [DPosMiner] [net](AdvService.java:200) Ready to broadcast block Num:1,ID:00000000000001206a3e24f26aa0c31033349e2cffab07f741061728a79a55b3
01:58:06.183 INFO  [DPosMiner] [DB](Manager.java:1233) Block num: 1, re-push-size: 0, pending-size: 0, block-tx-size: 0, verify-tx-size: 0
```
It also connects with the other fullnodes with log:
```Peer stats: channels 1, activePeers 1, active 0, passive 1```。

Check the other fullnode logs by running below command:
```
docker exec -it tron_node1 tail -f ./logs/tron.log
```
After initialization, it should show messages about syncing blocks, just following the SR.

**What docker-compose do?**

Check the [docker-compose.yml](https://github.com/tronprotocol/tron-deployment/blob/master/private_net/docker-compose.yml), the two container services use the same tron image with different configurations.

`ports`: Used in tron_witness service are exposed for API request to interact with Tron private network.

`command`: Used for Java-Tron image start-up arguments.
- `-jvm` is used for Java Virtual Machine parameters, which must be enclosed in double quotes and braces. `"{-Xmx10g -Xms10g}"` sets the maximum and initial heap size to 10GB.
- `-c` defines the configuration file to use.
- `-d` defines the database file to use. By mounting a local data directory, it ensures that the block data is persistent.
- `-w` means to start as a witness. You need to fill the `localwitness` field with private keys in the configuration file. Refer to the [**Run as Witness**](https://tronprotocol.github.io/documentation-en/using_javatron/installing_javatron/#startup-a-fullnode-that-produces-blocks).

## Run with customized configure

If you want to add more witness or other syncing fullnodes, you need to make below minimum changes for docker-compose.yml and configuration files.

**Add more services in docker-compose.yml**

Refer containers `tron_witness2` and `tron_node2` to add more witness and other fullnodes, make sure the configuration files changed accordingly following below details.

**Common Settings**

For all configurations, you need to set `node.p2p.version` to a same value and `node.discovery.enable = true`.
```
node {
 p2p {
    version = 1 # 11111: mainnet; 20180622: nilenet; others for private networks. 
  }
  ...
}

node.discovery = {
  enable = true  # you should set this entry value with true if you want your node can be discovered by other node.
  ...
}
```

**Witness Setting**

Make sure only one SR witness set `needSyncCheck = false`, the rest witness and other fullnodes all set `true`. This will make sure only one source of truth for block data.
```
block = {
  needSyncCheck = true # only one SR witness set false, the rest all false
```

If you want to add more witnesses:
- First, add the witness private key to the `localwitness` field in the witness configuration file.
- Then, add initial values to the `genesis.block` for all configuration files. Tron will use this to initialize the genesis block, and nodes with different genesis blocks will be disconnected.

```
localwitness = [
  # public address TCjptjyjenNKB2Y6EwyVT43DQyUUorxKWi
  0ab0b4893c83102ed7be35eee6d50f081625ac75a07da6cb58b1ad2e9c18ce43  # you must enable this value and the witness address are match.
]

genesis.block {
   assets = [ # set account initial balance
   ...
      { 
          accountName = "TestE"
          accountType = "AssetIssue"
          address = "TCjptjyjenNKB2Y6EwyVT43DQyUUorxKWi"
          balance = "1000000000000000"
      }
   ]
   witnesses = [ # set witness account initial vote count
    ...
    {
      address: TCjptjyjenNKB2Y6EwyVT43DQyUUorxKWi,
      url = "http://example.com",
      voteCount = 5000
    }
  ]
    
```

**P2P node discovery setting**

In witness configure file, make sure `node.listen.port` is set for p2p peer discovery.
```
node { 
  listen.port = 18888
  ... 
} 
```

Then, in other configuration files, add witness `container_name:port` to connect to the newly added witness fullnodes.
```
seed.node = {
  ip.list = [
    # used for docker deployment, to connect containers in tron_witness defined in docker-compose.yml
    "tron_witness1:18888",
    "tron_witness2:18888",
    ... 
  ]
}
```
### Advanced Configuration
Beside the above simple settings, there are a lot of fields you can modify to customize the behaviour of private networks. The configurations that you can change, though not exhaustively listed, include:
- ethereum compatible virtual machine in `vm = {...}`
- block settings
- network more detail settings for node discovery and connections, http and rpc service etc.
- enable or disable part of committee approved proposals
- [event subscription ](https://tronprotocol.github.io/documentation-en/architecture/event/#configure-node)
- [database configuration](https://tronprotocol.github.io/documentation-en/architecture/database/#database-configuration)

**Notice**: Make sure your changes is consistent among all configuration files, especially the SRs, as it may affect the block generation logic.

For example, you could change these block settings to a smaller value, to speed up the maintenance or proposal logic changes:

```
block = {
  maintenanceTimeInterval = 300000 # 5mins, default is 6 hours
  proposalExpireTime = 600000 # 10mins, default is 3 days
}
``` 
You could also enable below committee approved settings with `1`:
```
allowCreationOfContracts
allowMultiSign
allowAdaptiveEnergy
allowDelegateResource
allowSameTokenName
allowTvmTransferTrc10
```
For more detailed logic, you can refer to the detailed [logic](https://github.com/tronprotocol/java-tron/blob/develop/common/src/main/java/org/tron/common/parameter/CommonParameter.java). If you encounter any difficulties, please seek help in [Telegram](https://t.me/TronOfficialDevelopersGroupEn).


## Interact with Tron Private Network
For private networks started use this [docker-compose.yml](https://github.com/tronprotocol/tron-deployment/blob/master/private_net/docker-compose.yml) from GitHub. 
Notice the ports mapping:
```
ports:
- "8090:8090"       # for external http API request
- "50051:50051"     # for external rpc API request, for example through wallet-cli
```
After the network runs successfully, you can interact with it using the HTTP API or wallet-cli.
For example, a request to get genesis block info:
```
curl --location 'localhost:8090/wallet/getblock' \
--header 'Content-Type: application/json' \
--data '{
    "id_or_num": "0",
    "detail": true
}'
```
It should return transactions with type `TransferContract` for asset initialization set in `genesis.block` in configuration files.
```
{
    "blockID": "0000000000000000ad12b5787243011231c77e867e36f54ecb20b4b38ac594b8",
    "block_header": {
        "raw_data": {
            "txTrieRoot": "bf467bbfc436b1690f1c5d0d650ac4012fa2ff304f4e99bd487f90c8718e65ca",
            "witness_address": "41206e65772073797374656d206d75737420616c6c6f77206578697374696e672073797374656d7320746f206265206c696e6b656420746f67657468657220776974686f757420726571756972696e6720616e792063656e7472616c20636f6e74726f6c206f7220636f6f7264696e6174696f6e",
            "parentHash": "957dc2d350daecc7bb6a38f3938ebde0a0c1cedafe15f0edae4256a2907449f6"
        }
    },
    "transactions": [
        ...
    ]

```
If you request block info with num greater than 0, it should return empty response. As there is no transaction triggered.
For more API usage, please refer to [guidance](https://tronprotocol.github.io/documentation-en/getting_started/getting_started_with_javatron/#interacting-with-java-tron-nodes-using-curl).

To easily trigger a transaction on Tron network, [wallet-cli](https://tronprotocol.github.io/documentation-en/clients/wallet-cli/) is recommended. Refer the installation [guidance](https://github.com/tronprotocol/wallet-cli), make sure you edit config.conf in [src/main/resources](https://github.com/tronprotocol/wallet-cli/blob/develop/src/main/resources/config.conf) as below:
```
fullnode = {
  ip.list = [
    "localhost:50051" # or any value private network hosted
  ]
}
```
Wallet-cli will connect to your local private network. Then register or import wallet, you could trigger transaction easily. Check wallet-cli API usage [here](https://tronprotocol.github.io/documentation-en/clients/wallet-cli-command/#registerwallet).

## Troubleshot
If you encounter any difficulties, please refer to the [Issue Work Flow](https://tronprotocol.github.io/documentation-en/developers/issue-workflow/#issue-work-flow), then raise an issue on [GitHub](https://github.com/tronprotocol/java-tron/issues). For general questions please use [Discord](https://discord.gg/cGKSsRVCGm) or [Telegram](https://t.me/TronOfficialDevelopersGroupEn).

# Advance
To set up a private network natively, refer to the [Deployment Guide](https://tronprotocol.github.io/documentation-en/using_javatron/private_network/). Make sure you set up all the configuration parameters correctly.