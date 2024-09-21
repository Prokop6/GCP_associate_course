# Building a scecure Google Cloud Network: Solutions Lab

## Requirements

* setup firewall rules and vm tags
* bastion is only accessible via ssh with IAP
* bastion should not have an public IP
* juice-shop can be accessible via ssh only from bastion
* juice-shop is has public ip only for http

### Hints

* be mindful of tags and associated http rules
* be specific about firewall rules source ranges
* overly permissive rules should be avoided

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export PROJECT=

gcloud config set project $PROJECT

export SSH_IAP_NETWORK_TAG=
export HTTP_NETWORK_TAG=
export SSH_INTERNAL_NETWORK_TAG=

export NETWORK_NAME=
export SUBNET_NAME=

```

## Remove overly permissive firewall rules

```shell
gcloud compute firewall-rules list

```

run following for all rules looking to broad

```shell
gcloud compute firewall-rules delete

```

### Test

## Setup bastion

identify the bastion vm

```shell
gcloud compute instances list 

```

```shell
export BASTION_HOST_NAME=
export PROD_SERVER_NAME=
```

start the bastion vm

```shell
gcloud compute instances start $BASTION_HOST_NAME

```

### Test

```shell
gcloud compute instances add-tags $BASTION_HOST_NAME \
--tags $SSH_IAP_NETWORK_TAG 
```

```shell
gcloud compute instances add-tags $PROD_SERVER_NAME \
--tags $HTTP_NETWORK_TAG,$SSH_INTERNAL_NETWORK_TAG
```

## Configure firewall rules

### Configure IAP access

### Configure fw rule for IAP

```shell
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
--network $NETWORK_NAME \
--direction INGRESS \
--action allow \
--rules tcp:22 \
--source-ranges 35.235.240.0/20 \
--target-tags $SSH_IAP_NETWORK_TAG

```

the range `35.235.240.0/20` is used by IAP by default

possibly: add IAM policy bindings for specific users to give access to the VM

### Configure fw rule for internal connections

```shell
gcloud compute firewall-rules create allow-ssh-ingres-from-bastion \
--direction INGRESS \
--network $NETWORK_NAME \
--action allow \
--rules tcp:22 \
--source-tags $SSH_IAP_NETWORK_TAG \
--target-tags $SSH_INTERNAL_NETWORK_TAG

```

### Configure fw rule for external http to production

```shell
gcloud compute firewall-rules create allow-public-ssh-ingress \
--network $NETWORK_NAME \
--direction INGRESS \
--action allow \
--rules tcp:80 \
--source-ranges 0.0.0.0/0 \
--target-tags $HTTP_NETWORK_TAG

```

### Test
