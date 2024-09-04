gcloud auth login --cred-file creds.json

export PROJECT=qwiklabs-gcp-03-6da1a599c978

gcloud config set project $PROJECT

export NETWORK_NAME=my-internal-app
export SUBNET_A_NAME=subnet-a
export SUBNET_B_NAME=subnet-b

export REGION=us-east1
export ZONE_1=us-east1-c
# Same zone as ZONE_1 set on own discretion
export ZONE_2=us-east1-b

gcloud config set compute/region $REGION

export FW_NAME=my-internal-app
export TARGET_TAGS=lb-backend
export HC_RANGE_1='130.211.0.0/22'
export HC_RANGE_2='35.191.0.0/16'

read -p  "Continue..." -s
echo ""

############

echo "Create ingress firewall rule"

gcloud compute firewall-rules create 'app-allow-http' \
 --network=$FW_NAME \
 --target-tags=$TARGET_TAGS \
 --source-ranges='0.0.0.0/0' \
 --direction='INGRESS' \
 --allow='TCP:80'

echo "Create health check firewall rule"

gcloud compute firewall-rules create 'app-allow-health-check' \
 --target-tags=$TARGET_TAGS \
 --direction='INGRESS' \
 --source-ranges=$HC_RANGE_1,$HC_RANGE_2 \
 --allow='TCP'
# the task did not specify that the firewall rule should relate to the custom network


read -p  "Continue..." -s
echo ""

############

echo "Create instance templates"

export IT_1_NAME=instance-template-1
export IT_2_NAME=instance-template-2
# export IT_1_SERIES=E2
## case matters here!
# export IT_1_SERIES=e2
## also, valid machine type is required, not machine family (shows when creating instance group)
export IT_1_SERIES=e2-standard-2


export METADATA_1='startup-script-url=gs://gcloud-training/gcpnet/ilb/startup.sh'


gcloud compute instance-templates create $IT_1_NAME \
 --machine-type=$IT_1_SERIES \
 --tags=$TARGET_TAGS \
 --network=$NETWORK_NAME \
 --subnet=$SUBNET_A_NAME \
 --metadata=$METADATA_1
# --custom-vm-type=$IT_1_SERIES  should not be used as this is not a custom vm creating scenario


gcloud compute instance-templates create $IT_2_NAME \
 --machine-type=$IT_1_SERIES \
 --tags=$TARGET_TAGS \
 --network=$NETWORK_NAME \
 --subnet=$SUBNET_B_NAME \
 --metadata=$METADATA_1

gcloud compute instance-templates list

read -p  "Continue..." -s
echo ""

############

echo "### Create Managed instance groups ###"


export IG_1_NAME=instance-group-1
export IG_2_NAME=instance-group-2

gcloud compute instance-groups managed create $IG_1_NAME \
 --template=$IT_1_NAME \
 --zone=$ZONE_1 \
 --size=1

## either region OR zone can be specified


gcloud compute instance-groups managed create $IG_2_NAME \
 --template=$IT_2_NAME \
 --zone=$ZONE_2 \
 --size=1

gcloud compute instance-groups managed set-autoscaling $IG_1_NAME \
 --min-num-replicas=1 \
 --max-num-replicas=5 \
 --target-cpu-utilization=$((80/100)) \
 --cool-down-period=45 \
 --zone=$ZONE_1

## target CPU util must be < 1.0
## requires zone info if i-g created in a zone - it searches the region for the i-g instead


gcloud compute instance-groups managed set-autoscaling $IG_2_NAME \
 --max-num-replicas=5 \
 --min-num-replicas=1 \
 --target-cpu-utilization=$((80/100)) \
 --cool-down-period=45 \
 --zone=$ZONE_2

gcloud compute instance-groups managed list


read -p  "Continue..." -s
echo ""

############

echo "### Creating util vm"

export UTILITY_CUSTOM_IP_NAME=utility-custom-ip

#gcloud compute addresses create $UTILITY_CUSTOM_IP_NAME \
# --addresses=10.10.20.50 \
# --subnet=$SUBNET_A_NAME \
# --region=$REGION

## ephemeral IP allocation is required prior to setting it as vm address
## it is not - IP reservation creates a static IP address not an ephemeral one

gcloud compute instances create utility-vm \
 --zone=$ZONE_1 \
 --machine-type=e2-micro \
 --network=$NETWORK_NAME \
 --subnet=$SUBNET_A_NAME \
 --private-network-ip=10.10.20.50

#--address=$UTILITY_CUSTOM_IP_NAME
## use private-network-ip for emphemeral custom ip declaration


read -p "Contnue?" -s
echo ""

############

echo "### Create health check ###"

export HC_NAME=my-ilb-health-check

gcloud compute health-checks create http $HC_NAME \
 --port=80 

echo "### Create backends ###"

export BE_SERVICE_NAME=my-backend-service

gcloud compute backend-services create $BE_SERVICE_NAME \
 --global

gcloud compute backend-services add-backend $BE_SERVICE_NAME \
 --instance-group=$IG_1_NAME

gcloud compute backend-services add-backend $BE_SERVICE_NAME \
 --instance-group=$IG_2_NAME

echo "### Create IP address ### "

export IP_ADDRESS_NAME=my-ilb-ip

gcloud compute addresses create $IP_ADDRESS_NAME \
 --addresses=10.10.30.5 

echo "### Create LB FrontEnd ### "

export LB_NAME=my-ilb

gcloud compute forwarding-rules create $LB_NAME \
    --region=$REGION \
    --load-balancing-scheme=internal \
    --network=$NETWORK \
    --address=10.1.2.99 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=$BE_SERVICE_NAME \
    --backend-service-region=$REGION

