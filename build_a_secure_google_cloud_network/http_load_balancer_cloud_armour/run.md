# HTTP load balancer with Cloud Armour

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export PROJECT=
export REGION_1=
export REGION_2=

gcloud config set project $PROJECT
```

### Configure HTTP and health check firewall rules

```shell
export FW_RULE_NAME='default-allow-http'
export FW_TARGET_TAG='http-server'
```

```shell
gcloud compute firewall-rules create $FW_RULE_NAME \
--network 'default' \
--target-tags $FW_TARGET_TAG \
--allow 'TCP:80' \
--source-ranges '0.0.0.0/0' \
--direction 'INGRESS'
```

### Create Health Check rule

```shell
export HC_FW_RULE_NAME="default-allow-health-check"

export HC_SOURCE_RANGE_1="130.211.0.0/22"
export HC_SOURCE_RANGE_2="35.191.0.0/16"
```

```shell
gcloud compute firewall-rules create $HC_FW_RULE_NAME \
--network 'default' \
--target-tags $FW_TARGET_TAG \
--source-ranges $HC_SOURCE_RANGE_1,$HC_SOURCE_RANGE_2 \
--allow 'TCP' \
--direction 'INGRESS'
```

### Test

## Configure instance templates and create instance groups

### Configure instance templates

```shell
export IT_1_NAME="${REGION_1}-template"
export IT_1_LOCATION='GLOBAL'
export IT_1_SERIES='E2'
export IT_1_MACHINE_TYPE='e2-micro'

export IT_1_NETWORK_TAGS=${TARGET_TAGS}
export IT_1_NETWORK="default"
export IT_1_SUBNETWORK="default"
export IT_1_KEY_1="startup-script-url"
export IT_1_VALUE_1="gs://cloud-training/gcpnet/httplb/startup.sh"
```

```shell
export IT_2_NAME="${REGION_2}-template"
export IT_2_LOCATION="GLOBAL"
export IT_2_SERIES=${IT_1_SERIES}
export IT_2_MACHINE_TYPE=${IT_1_MACHINE_TYPE}

# advanced options
export IT_2_NETWORK_TAGS=${IT_1_NETWORK_TAGS}
export IT_2_NETWORK=${IT_1_NETWORK}
export IT_2_SUBNETWORK="default"
export IT_2_KEY_1=${IT_1_KEY_1}
export IT_2_VALUE_1=${IT_1_VALUE_1}
```

```shell
gcloud compute instance-templates create $IT_1_NAME \
--machine-type ${IT_1_MACHINE_TYPE} \
--network ${IT_1_NETWORK} \
--tags ${IT_1_NETWORK_TAGS} \
--subnet ${IT_1_SUBNETWORK} \
--region ${REGION_1} \
--metadata ${IT_1_KEY_1}=${IT_1_VALUE_1}
```

```shell
gcloud compute instance-templates create ${IT_2_NAME} \
--machine-type ${IT_2_MACHINE_TYPE} \
--network ${IT_2_NETWORK} \
--tags ${IT_2_NETWORK_TAGS} \
--subnet ${IT_2_SUBNETWORK} \
--region ${REGION_2} \
--metadata ${IT_2_KEY_1}=${IT_2_VALUE_1}
```

```shell
gcloud compute instance-templates list
```

### Configure managed instance groups

```shell
export IG_1_NAME=$REGION_1-mig
export IG_1_TEMPLATE=$REGION_1-template
export IG_1_REGION=$REGION_1
export IG_1_LOCATION=$(gcloud compute zones list --filter="region:(${IG_1_REGION})" --format="csv[no-heading](name)")
export IG_1_MIN_INSTANCES=1
export IG_1_MAX_INSTANCES=2
export IG_1_AUTOSCALING_SIGNAL=CPU_UTIL
export IG_1_TARGET_CPU_UTIL=0.80
export IG_1_INIT_TIME=45
export IG_1_ZONES=$(gcloud compute zones list --filter="region:(${IG_1_REGION})" --format="csv[no-heading](name)")
```

```shell
export IG_2_NAME=$REGION_2-mig
export IG_2_TEMPLATE=$REGION_2-template
export IG_2_REGION=$REGION_2
export IG_2_LOCATION=$(gcloud compute zones list --filter="region:(${IG_2_REGION})" --format="csv[no-heading](name)")
export IG_2_MIN_INSTANCES=1
export IG_2_MAX_INSTANCES=2
export IG_2_AUTOSCALING_SIGNAL=CPU_UTIL
export IG_2_TARGET_CPU_UTIL=0.80
export IG_2_INIT_TIME=45
export IG_2_ZONES=$(gcloud compute zones list --filter="region:(${IG_2_REGION})" --format="csv[no-heading](name)")
```

```shell
gcloud compute instance-groups managed create ${IG_1_NAME} \
--template ${IG_1_TEMPLATE} \
--region ${IG_1_REGION} \
--size ${IG_1_MIN_INSTANCES} \

gcloud compute instance-groups managed set-autoscaling ${IG_1_NAME} \
--region ${IG_1_REGION} \
--max-num-replicas ${IG_1_MAX_INSTANCES} \
--target-cpu-utilization ${IG_1_TARGET_CPU_UTIL} \
--cool-down-period ${IG_1_INIT_TIME}
```

```shell
gcloud compute instance-groups managed create ${IG_2_NAME} \
--template ${IG_2_TEMPLATE} \
--region ${IG_2_REGION} \
--size ${IG_2_MIN_INSTANCES}

gcloud compute instance-groups managed set-autoscaling ${IG_2_NAME} \
--region ${IG_2_REGION} \
--max-num-replicas ${IG_2_MAX_INSTANCES} \
--target-cpu-utilization ${IG_2_TARGET_CPU_UTIL} \
--cool-down-period ${IG_2_INIT_TIME}
```

### Test

### Verify backends

*this can be skipped*

## Configure HTTP Load Balancer

Load balancers consist of the following:

* health check
* backend service and its instance groups
* an url-map with default service

```shell
export HC_NAME="http-health-check"
export LB_NAME="http-lb"
export URL_MAP_NAME="http-default-map"

export BACKEND_SERVICE_NAME="http-backend"
```

```shell
gcloud compute health-checks create tcp $HC_NAME \
--port 80 \
--enable-logging \
--check-interval 5 \
--healthy-threshold 2 \
--timeout 5s \
--unhealthy-threshold 2 \
--global
```

```shell
gcloud compute backend-services create ${BACKEND_SERVICE_NAME} \
--global \
--health-checks ${HC_NAME} 
```

keep in mind - health checks are required for backend-service

```shell
gcloud compute backend-services add-backend ${BACKEND_SERVICE_NAME} \
--instance-group ${IG_1_NAME} \
--instance-group-region ${IG_1_REGION} \
--balancing-mode "RATE" \
--global \
--max-rate-per-instance 50
```

*omitting max-rate - should not be set by autoscaling managed instances*

```shell
gcloud compute backend-services add-backend ${BACKEND_SERVICE_NAME} \
--instance-group ${IG_2_NAME} \
--instance-group-region ${IG_2_REGION} \
--global \
--balancing-mode "UTILIZATION" \
--max-utilization "0.80"
```

```shell
gcloud compute url-maps create ${URL_MAP_NAME} \
--default-service ${BACKEND_SERVICE_NAME}
```

```shell
gcloud compute target-http-proxies create ${LB_NAME}-proxy \
--url-map ${URL_MAP_NAME}
```

```shell
gcloud compute forwarding-rules create ${LB_NAME}-forward-ipv4 \
--load-balancing-scheme "EXTERNAL" \
--target-http-proxy ${LB_NAME}-proxy \
--global \
--ip-version IPV4 \
--ports 80
```

```shell
gcloud compute forwarding-rules create ${LB_NAME}-forward-ipv6 \
--load-balancing-scheme "EXTERNAL" \
--target-http-proxy ${LB_NAME}-proxy \
--global \
--ip-version IPV6 \
--ports 80
```

### Test

## Test the HTTP Load Balancer

*Test if connection to LB IP is resolved correctly*

### Create a siege vm

```shell
export VM_NAME=siege-vm
export REGION_3=us-east4
export ZONE_3=us-east4-c
export series="E2"
```

```shell
gcloud compute instances create ${VM_NAME} \
--zone ${ZONE_3} \
--machine-type "e2-standard-2"
```

### Lunch Stress Test

* Access the Siege VM via SSH
* set LB IP to ctx

```shell
export LB_IP=
```

* Instal Siege

```shell
sudo apt-get -y install siege
```

* run siege

```shell
siege \
-c 150 \
-t120s \
http://${LB_IP}

```

### Deny-list siege vm

```shell
export SIEGE_IP=35.194.83.136
export DENYLIST_NAME=denylist-siege
```

create policy:

```shell
gcloud compute security-policies create ${DENYLIST_NAME} \
--type "CLOUD_ARMOR" \
--global
```

create rule in said policy:

```shell
gcloud compute security-policies rules create 1000 \
--action deny-403 \
--security-policy ${DENYLIST_NAME} \
--src-ip-ranges ${SIEGE_IP}
```

### Test

*additionally try to access the Proxy from Siege*
