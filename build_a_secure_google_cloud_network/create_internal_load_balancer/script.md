# Create an internal load balancer

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export PROJECT=
export REGION=
export SUBNET_A_ZONE=
export SUBNET_B_ZONE=

gcloud config set project $PROJECT
gcloud config set compute.region $REGION

```

```shell
export NETWORK_NAME=my-internal-app

export SUBNET_A_NAME=subnet-a
export SUBNET_B_NAME=subnet-b

```

the subnets are in a region - Internal Load Balancer is an regional resource

managed instance groups are in different Zones - protection against zonal failures

### Create health check firewall rules

### Create HTTP firewall rule

create fw rule for target specified by tag, in IPv4 range, to allow TCP traffic on port 80

```shell
export FW_RULE_NAME=app-allow-http
export FW_TARGET_TAG=lb-backend

```

```shell
gcloud compute firewall-rules create $FW_RULE_NAME \
--network $NETWORK_NAME \
--source-ranges "0.0.0.0/0" \
--target-tags $FW_TARGET_TAG \
--direction "INGRESS" \
--allow "TCP:80"

```

### Create health check firewall rule

create fw rule for targets specified by tag, from google default health check IPs, allowing TCP traffic

```shell
export HC_FW_RULE=app-allow-health-check

```

```shell
gcloud compute firewall-rules create $HC_FW_RULE \
--source-ranges "130.211.0.0/22,35.191.0.0/16" \
--target-tags $FW_TARGET_TAG \
--direction "INGRESS" \
--allow "TCP"

```

the task did not specify that the firewall rule should relate to the custom network

### Test

## Configure instance templates and groups

instance templates in both subnets of the network are required

the templates should be located globally (specified in details)

the VM series should be E2 (e2-standard-2 is default)

```shell
export IT_1_NAME=instance-template-1
export IT_2_NAME=instance-template-2

export IT_MACHINE_TYPE=e2-standard-2

export METADATA_KEY_1=startup-script-url
export METADATA_VALUE_1="gs://cloud-training/gcpnet/ilb/startup.sh"

```

for instance-templates `--region` relates to the subnet region whilst `--instance-template-region` - to the region where the instance template should be created

```shell
gcloud compute instance-templates create $IT_1_NAME \
--machine-type $IT_MACHINE_TYPE \
--tags $FW_TARGET_TAG \
--network $NETWORK_NAME \
--subnet $SUBNET_A_NAME \
--metadata "${METADATA_KEY_1}=${METADATA_VALUE_1}" \
--region $REGION

```

```shell
gcloud compute instance-templates create $IT_2_NAME \
--region $REGION \
--machine-type $IT_MACHINE_TYPE \
--tags $FW_TARGET_TAG \
--network $NETWORK_NAME \
--subnet $SUBNET_B_NAME \
--metadata "${METADATA_KEY_1}=${METADATA_VALUE_1}"

```

### Create managed instance groups

```shell
export IG_1_NAME=instance-group-1
export IG_2_NAME=instance-group-2

```

the details of the task show REGION and ZONE specified, but test runs show that api accepts only one of those values a time

the autoscaling/minimum num of instances param is represented with the flag "size"

```shell
gcloud compute instance-groups managed create $IG_1_NAME \
--template $IT_1_NAME \
--zone $SUBNET_A_ZONE \
--size 1

gcloud compute instance-groups managed create $IG_2_NAME \
--template $IT_2_NAME \
--zone $SUBNET_B_ZONE \
--size 1

```

autoscaling for both groups should be set to CPU util 80%, with 45 initialization time

instance groups are zone-related, so zone must be specified in the api call to designate the IG properly

```shell
gcloud compute instance-groups managed set-autoscaling $IG_1_NAME \
--min-num-replicas 1 \
--max-num-replicas 5 \
--target-cpu-utilization 0.8 \
--cool-down-period 45 \
--zone $SUBNET_A_ZONE

```

```shell
gcloud compute instance-groups managed set-autoscaling $IG_2_NAME \
--min-num-replicas 1 \
--max-num-replicas 5 \
--target-cpu-utilization "0.80" \
--cool-down-period 45 \
--zone $SUBNET_B_ZONE

```

### Create an utility VM

```shell
gcloud compute instances create utility-vm \
--zone $SUBNET_A_ZONE \
--machine-type e2-micro \
--network $NETWORK_NAME \
--subnet $SUBNET_A_NAME \
--private-network-ip "10.10.20.50"

```

### Test

## Configure the internal load balancer

create an pass-through load balancer

```shell
export LB_NAME=my-ilb

```

health checks are required for backend services, backend service is required for proxy

### Configure health check

```shell
export HC_NAME=my-ilb-health-check

export BE_SERVICE_NAME=be-service

```

```shell
gcloud compute health-checks create tcp $HC_NAME \
--global \
--enable-logging \
--check-interval 5 \
--healthy-threshold 2 \
--unhealthy-threshold 2 \
--timeout 5s \
--port 80

```

the load balancer should be regional, hence `--region` must be defined

```shell
gcloud compute backend-services create $BE_SERVICE_NAME \
--region $REGION \
--health-checks $HC_NAME \
--load-balancing-scheme "INTERNAL"

```

```shell
gcloud compute backend-services add-backend $BE_SERVICE_NAME \
--region $REGION \
--instance-group $IG_1_NAME \
--instance-group-zone $SUBNET_A_ZONE

gcloud compute backend-services add-backend be-service \
--region $REGION \
--instance-group $IG_2_NAME \
--instance-group-zone $SUBNET_B_ZONE

```

```shell
export LB_NAME=my-ilb

```

the forwarding rules must relate to a specific IP address (10.10.30.5 in the task) that is part of one of the network and its sub-network, both network and sub-network must also be designated

```shell
gcloud compute forwarding-rules create $LB_NAME \
--region $REGION \
--load-balancing-scheme internal \
--address 10.10.30.5 \
--ip-protocol TCP \
--ports 80 \
--backend-service $BE_SERVICE_NAME \
--backend-service-region $REGION \
--network $NETWORK_NAME \
--subnet $SUBNET_B_NAME  

```
