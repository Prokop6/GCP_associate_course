# VPC network peering

> connecting two networks of different projects

## Basic setup

```shell
gcloud auth login --cred-file creds_a.json
gcloud auth login --cred-file creds_b.json

export PROJECT_A=qwiklabs-gcp-04-fcfdd5b91710
export SA_A_NAME=${PROJECT_A}@${PROJECT_A}.iam.gserviceaccount.com

export PROJECT_B=qwiklabs-gcp-02-7d879db759fc
export SA_B_NAME=${PROJECT_B}@${PROJECT_B}.iam.gserviceaccount.com

export REGION_A=us-central1
export ZONE_A=${REGION_A}-a
export REGION_B=us-west1
export ZONE_B=${REGION_B}-b
```


## Create networks

### Project A

```shell
export NETWORK_A_NAME=network-a
export SUBNET_A_NAME=network-a-subnet
export INSTANCE_A_NAME=vm-a
```

```shell
gcloud config set core/account $SA_A_NAME
gcloud config set project $PROJECT_A
```

```shell
gcloud compute networks create $NETWORK_A_NAME \
 --subnet-mode custom

gcloud compute networks subnets create $SUBNET_A_NAME \
 --network $NETWORK_A_NAME \
 --range 10.0.0.0/16 \
 --region $REGION_A
```

#### create vm in subnet

```shell
gcloud compute instances create $INSTANCE_A_NAME \
 --zone $ZONE_A \
 --network $NETWORK_A_NAME \
 --subnet $SUBNET_A_NAME \
 --machine-type e2-small
```

#### create firewall rule

```shell
gcloud compute firewall-rules create ${NETWORK_A_NAME}-fw\
 --network $NETWORK_A_NAME \
 --allow tcp:22,icmp
```

#### Test

### Project B

```shell
export NETWORK_B_NAME=network-b
export SUBNET_B_NAME=network-b-subnet
export INSTANCE_B_NAME=vm-b
```

```shell
gcloud config set core/account $SA_B_NAME
gcloud config set project $PROJECT_B
```

```shell
gcloud compute networks create $NETWORK_B_NAME \
 --subnet-mode custom

gcloud compute networks subnets create $SUBNET_B_NAME \
 --network $NETWORK_B_NAME \
 --range 10.8.0.0/16 \
 --region $REGION_B
```

#### create vm in subnet

```shell
gcloud compute instances create $INSTANCE_B_NAME \
 --zone $ZONE_B \
 --network $NETWORK_B_NAME \
 --subnet $SUBNET_B_NAME \
 --machine-type e2-small
```

#### create firewall rule

```shell
gcloud compute firewall-rules create ${NETWORK_B_NAME}-fw\
 --network $NETWORK_B_NAME \
 --allow tcp:22,icmp
```

### Test

## Peer networks 

```shell
export PEER_AB_NAME=peer-ab
export PEER_BA_NAME=peer-ba
```

### Peer a to b

```shell
gcloud config set core/account $SA_A_NAME
gcloud config set project $PROJECT_A

gcloud compute networks peerings create $PEER_AB_NAME \
 --network $NETWORK_A_NAME \
 --peer-project $PROJECT_B \
 --peer-network $NETWORK_B_NAME
```

#### Test


### Peer b to a

```shell
gcloud config set core/account $SA_B_NAME
gcloud config set project $PROJECT_B

gcloud compute networks peerings create $PEER_BA_NAME \
 --network $NETWORK_B_NAME \
 --peer-project $PROJECT_A \
 --peer-network $NETWORK_A_NAME
```

#### Test

```bash

gcloud compute routes list --project 

```

ping from A to B and from B to A
