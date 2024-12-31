# Private Network

Here are the quick-start for setting up a Tron private network using Docker.

A private chain needs at least one fullnode running by [SR](https://tronprotocol.github.io/documentation-en/mechanism-algorithm/sr/) to produces blocks, and any number of FullNodes to synchronize blocks and broadcast transactions.

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

`ports`: Used in tron_witness service are exposed for p2p node discovery and API request. These ports
also need properly set in both configuration files, which will be explained later with more detail.

`command`: Used for Java-Tron image start-up arguments.
- `-jvm` is used for Java Virtual Machine parameters, which must be enclosed in double quotes and braces. `"{-Xmx10g -Xms10g}"` sets the maximum and initial heap size to 10GB.
- `-c` defines the configuration file to use.
- `-d` defines the database file to use. You can mount a directory for `datadir` with snapshots. Please refer to [**Lite-FullNode**](https://tronprotocol.github.io/documentation-en/using_javatron/backup_restore/#_5). This will populate the private network with some real transaction data.
- `-w` means to start as a witness. You need to fill the `localwitness` field with private keys in the configuration file. Refer to the [**Run as Witness**](https://tronprotocol.github.io/documentation-en/using_javatron/installing_javatron/#startup-a-fullnode-that-produces-blocks).


## Run with customized configure

If you want to add more witness or other syncing fullnodes, you need to make below minimum changes for docker-compose.yml and configuration files.

**Add more services in docker-compose.yml**

**P2P node discovery setting**

In witness configure file, set below used for p2p peer nodes discovery.
```
node { 
  listen.port = 1888X 
  ... 
} 
```
 

Then in others conf add `witness container name:1888X`
```
seed.node = {
  ip.list = [
    # used for docker deployment, to connect container named in tron_witness, defined in docker-compose.yml
    "tron_witness1:18888",
    "tron_witness2:18887",
    ... 
  ]
}
```

witness setting

Thus, if you want to add more witnesses or other normal syncing fullnode services, just add the corresponding services in the docker-compose.yml file. To avoid port conflicts, make sure you differentiate the port mappings and change the corresponding values in the respective configuration files.


## Interact with Tron Private Network


## Troubleshot
If you encounter any difficulties, please refer to the [Issue Work Flow](https://tronprotocol.github.io/documentation-en/developers/issue-workflow/#issue-work-flow), then raise an issue on [GitHub](https://github.com/tronprotocol/java-tron/issues). For general questions please use [Discord](https://discord.gg/cGKSsRVCGm) or [Telegram](https://t.me/TronOfficialDevelopersGroupEn).

# Advance
To set up a private network natively, refer to the [Deployment Guide](https://tronprotocol.github.io/documentation-en/using_javatron/private_network/). Make sure you set up all the configuration parameters mentioned above correctly.