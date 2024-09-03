export PROJECT=qwiklabs-gcp-02-514de7b5955b 
export REGION_1=us-central1
export REGION_2=us-east4
export REGION_3=

gcloud config set project $PROJECT

#Create firewall rule

export FW_RULE_NAME=default-allow-http
export NETWORK=default

# targets - specified target tags

export TARGET_TAGS=http-server

# source filter - IPv4 Ranges

export SOURCE_RANGE="0.0.0.0/0"

export PROTOCOL=TCP
export PORT="80"

gcloud compute firewall-rules create $FW_RULE_NAME \
 --network=$NETWORK \
 --target-tags=$TARGET_TAGS \
 --source-ranges=$SOURCE_RANGE \
 --allow=$PROTOCOL:$PORT \
 --direction=INGRESS

## Create firewall health check

export HC_WF_RULE_NAME=default-allow-health-check

export HC_SOURCE_RANGE_1="130.211.0.0/22"
export HC_SOURCE_RANGE_2="35.191.0.0/16"


gcloud compute firewall-rules create $HC_WF_RULE_NAME \
 --network=$NETWORK \
 --target-tags=$TARGET_TAGS \
 --source-ranges=$HC_SOURCE_RANGE_1,$HC_SOURCE_RANGE_2 \
 --allow=$PROTOCOL \
 --direction=INGRESS


## configure instance templates

export IT_1_NAME=$REGION_1-template
export IT_1_LOCATION=GLOBAL
export IT_1_SERIES=E2
export IT_1_MACHINE_TYPE=e2-micro

# advanced options
export IT_1_NETWORK_TAGS=http-server
export IT_1_NETWORK=default
export IT_1_SUBNETWORK=$REGION_1
export IT_1_KEY_1=startup-script-url
export IT_1_VALUE_1="gs://cloud-training/gcpnet/httplb/startup.sh"


export IT_2_NAME=$REGION_2-template
export IT_2_LOCATION=$IT_1_LOCATION
export IT_2_SERIES=$IT_1_SERIES
export IT_2_MACHINE_TYPE=$IT_1_MACHINE_TYPE

# advanced options
export IT_2_NETWORK_TAGS=$IT_1_NETWORK_TAGS
export IT_2_NETWORK=$IT_1_NETWORK
export IT_2_SUBNETWORK=$REGION_2
export IT_2_KEY_1=$IT_1_KEY_1
export IT_2_VALUE_1=$IT_1_VALUE_1

gcloud compute instance-templates create $IT_1_NAME \
 --machine-type=$IT_1_MACHINE_TYPE \
 --network=$IT_1_NETWORK \
 --tags=$IT_1_NETWORK_TAGS \
 --subnet=$IT_1_SUBNETWORK \
 --region=$REGION_1 \
 --metadata=$IT_1_KEY_1=$IT_1_VALUE_1


gcloud compute instance-templates create $IT_2_NAME \
 --machine-type=$IT_2_MACHINE_TYPE \
 --network=$IT_2_NETWORK \
 --tags=$IT_2_NETWORK_TAGS \
 --subnet=$IT_2_SUBNETWORK \
 --region=$REGION_2 \
 --metadata=$IT_2_KEY_1=$IT_2_VALUE_1


gcloud compute instance-templates list

echo  "create managed instance groups..."

export IG_1_NAME=$REGION_1-mig
export IG_1_TEMPLATE=$REGION_1-template
export IG_1_LOCATION=multiple zones
export IG_1_REGION=$REGION_1
export IG_1_MIN_INSTANCES=1
export IG_1_MAX_INSTANCES=2
export IG_1_AUTOSCALING_SIGNAL=CPU_UTIL
export IG_1_TARGET_CPU_UTIL=80
export IG_1_INIT_TIME=45
export IG_1_ZONES=$(gcloud compute zones list)

export IG_2_NAME=$REGION_2-mig
export IG_2_TEMPLATE=$REGION_2-template
export IG_2_LOCATION=multiple zones
export IG_2_REGION=$REGION_2
export IG_2_MIN_INSTANCES=1
export IG_2_MAX_INSTANCES=2
export IG_2_AUTOSCALING_SIGNAL=CPU_UTIL
export IG_2_TARGET_CPU_UTIL=80
export IG_2_INIT_TIME=45
export IG_2_ZONES=$()


gcloud compute instance-groups managed create $IG_1_NAME \
 --template=$IG_1_TEMPLATE \
 --region=$IG_1_REGION \
 --size=$IG_1_MIN_INSTANCES \

gcloud compute instance-groups managed set-autoscaling $IG_1_NAME \
 --max-num-replicas=$IG_1_MAX_INSTANCES \
 --target-cpu-utilization=$IG_1_TARGET_CPU_UTIL \
 --cool-down-period=$_IG_1_INIT_TIME 

gcloud compute instance-groups managed create $IG_2_NAME \
 --template=$IG_2_TEMPLATE \
 --region=$IG_2_REGION \
 --size=$IG_2_MIN_INSTANCES 

gcloud compute instance-groups managed set-autoscaling $IG_2_NAME \
 --max-num-replicas=$IG_2_MAX_INSTANCES \
 --target-cpu-utilization=$IG_2_TARGET_CPU_UTIL \
 --cool-down-period=$_IG_2_INIT_TIME

echo "create health check"

export HC_NAME=http-health-check

gcloud compute health-checks create http $HC_NAME \
 --port=80 \
 --enable-logging \
 --check-interval=5 \
 --healthy-threshold=2 \
 --timeout=5s \
 --unhealthy-threshold=2

## create backends

export BACKEND_SERVICE_NAME=http-backend

gcloud compute backend-services create $BACKEND_SERVICE_NAME \
 --global

gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
 --instance-group=$IG_1_NAME \
 --balancing-mode=RATE \
 --max-rate-per-instance=50

## omitting max-rate - should not be set by autoscaling managed instances

gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
 --instance-group=$IG_2_NAME \
 --balancing-mode=UTILIZATION \
 --max-connections-per-instance=80
 
