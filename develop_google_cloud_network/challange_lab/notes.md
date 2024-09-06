# Develop your Google Cloud Network Challange Lab

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export PROJECT=qwiklabs-gcp-01-ac04e9ca2d9a
export ZONE=us-east1-c
export REGION=us-east1

export ADDITIONAL_USER_NAME=student-01-c67bcb073edd@qwiklabs.net

export MACHINE_TYPE=e2-medium

gcloud config set project $PROJECT
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

```

## Create development VPC

```shell
export NETWORK_DEV_NAME=griffin-dev-vpc

export SUBNET_DEV_WP_NAME=griffin-dev-wp
export SUBNET_DEV_WP_RANGE=192.168.16.0/20

export SUBNET_DEV_MGMT_NAME=griffin-dev-mgmt
export SUBNET_DEV_MGMT_RANGE=192.168.32.0/20
```

```shell
gcloud compute networks create $NETWORK_DEV_NAME \
 --subnet-mode custom

gcloud compute networks subnets create $SUBNET_DEV_WP_NAME \
 --network=$NETWORK_DEV_NAME \
 --range=$SUBNET_DEV_WP_RANGE \
 --region=$REGION

gcloud compute networks subnets create $SUBNET_DEV_MGMT_NAME \
 --network=$NETWORK_DEV_NAME \
 --range=$SUBNET_DEV_MGMT_RANGE \
 --region=$REGION
```

```shell
gcloud compute firewall-rules create ${NETWORK_DEV_NAME}-fw\
 --network $NETWORK_DEV_NAME \
 --allow tcp:22,icmp
```

### Test

## Create prod VPC

```shell
export NETWORK_PROD_NAME=griffin-prod-vpc

export SUBNET_PROD_WP_NAME=griffin-prod-wp
export SUBNET_PROD_WP_RANGE=192.168.48.0/20

export SUBNET_PROD_MGMT_NAME=griffin-prod-mgmt
export SUBNET_PROD_MGMT_RANGE=192.168.64.0/20
```

```shell
gcloud compute networks create $NETWORK_PROD_NAME \
 --subnet-mode custom

gcloud compute networks subnets create $SUBNET_PROD_WP_NAME \
 --network=$NETWORK_PROD_NAME \
 --range=$SUBNET_PROD_WP_RANGE \
 --region=$REGION

gcloud compute networks subnets create $SUBNET_PROD_MGMT_NAME \
 --network=$NETWORK_PROD_NAME \
 --range=$SUBNET_PROD_MGMT_RANGE \
 --region=$REGION
```


```shell
gcloud compute firewall-rules create ${NETWORK_PROD_NAME}-fw\
 --network $NETWORK_PROD_NAME \
 --allow tcp:22,icmp
```

### Test

## Create Bastion host

```shell
export BASTION_NAME=griffin-bastion
```

> No spaces inbetween the arguments in a list

```shell
gcloud compute instances create $BASTION_NAME \
 --zone $ZONE \
 --machine-type $MACHINE_TYPE \
 --network-interface \
    network=$NETWORK_DEV_NAME,subnet=$SUBNET_DEV_MGMT_NAME \
 --network-interface \
    network=$NETWORK_PROD_NAME,subnet=$SUBNET_PROD_MGMT_NAME
```

### Test

## Create and configure SQL instance

```shell
export DB_DEV_NAME=griffin-dev-db
export PG_PASSWORD=123456789
```

```shell
gcloud sql instances create $DB_DEV_NAME \
 --zone $ZONE \
 --root-password $PG_PASSWORD
```

the SQL connection from host fails due to some IPv6 issues, 
confinue from cloud console

```shell
gcloud sql connect $DB_DEV_NAME \
 --user root
```

run:

```sql
CREATE DATABASE wordpress;
CREATE USER "wp_user"@"%" IDENTIFIED BY "stormwind_rules";
GRANT ALL PRIVILEGES ON wordpress.* TO "wp_user"@"%";
FLUSH PRIVILEGES;
```

### Test


## Create Kubernetes cluster

```shell
export NODES=2
export NODE_TYPE=e2-standard-4
export CLUSTER_NAME=griffin-dev
export CLUSTER_SUBNET=$SUBNET_DEV_WP_NAME
```

```shell
gcloud container clusters create $CLUSTER_NAME \
 --machine-type $NODE_TYPE \
 --num-nodes $NODES \
 --zone $ZONE \
 --network $NETWORK_DEV_NAME\
 --subnetwork $CLUSTER_SUBNET
```

### Test

## Configure Kubernetes cluster

```shell
export CLUSTER_SOURCE=gs://cloud-training/gsp321/wp-k8s
export WP_NAME=wp_user
export WP_PASS=stormwind_rules

export WP_ENV=wp-env.yaml
```

reexport `CLUSTER_NAME` and `ZONE` on Google Console

```shell
gsutil cp $CLUSTER_SOURCE .
```

update `$WP_ENV` file manualy, the persistant volume claim is sufficient for volume declaration 

```shell
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

kubectl apply -f wp-env.yaml
```

```shell
gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@${PROJECT}.iam.gserviceaccount.com

kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json
```

### Test

## Deploy

Do this in Google Console

### Test

## Enable monitoring

take data from kubectl:

```shell
export SERVICE_LB_ADDRESS=
```

```shell
gcloud services enable monitoring --project $PROJECT

gcloud monitoring uptime create griffin-uptime-check \
 --resource-labels=host=$SERVICE_LB_ADDRESS,project_id=$PROJECT \
 --resource-type=uptime-url
```

### Test

## Provide access for an additional engineer

```shell
gcloud projects add-iam-policy-binding $PROJECT \
 --member user:$ADDITIONAL_USER_NAME  \
 --role roles/editor
```


### Test
