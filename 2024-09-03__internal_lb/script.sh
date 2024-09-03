export PROJECT=qwiklabs-gcp-04-07ab4338ef5f

gcloud config set project $PROJECT

export NETWORK_NAME=my-internal-app
export SUBNET_A_NAME=subnet-a
export SUBNET_B_NAME=subnet-b

export REGION=us-east1
export ZONE_1=us-east1-b
# Same zone as ZONE_1 set on own discretion
export ZONE_2=us-east1-c

gcloud config set compute/region $REGION

export FW_NAME=my-internal-app
export TARGET_TAGS=lb-backend
export HC_RANGE_1='130.211.0.0/22'
export HC_RANGE_2='35.191.0.0/16'

read -p  "Continue...\n" -s

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
 --network=$FW_NAME \
 --target-tags=$TARGET_TAGS \
 --direction='INGRESS' \
 --source-ranges=$HC_RANGE_1,$HC_RANGE_2 \
 --allow='TCP'

read -p  "Continue...\n" -s

############

echo "Create instance templates"

export IT_1_NAME=instance-template-1
export IT_2_NAME=instance-template-2
export IT_1_SERIES=E2
export METADATA_1='startup-script-url=gs://gcloud-training/gcpnet/ilb/startup.sh'


gcloud compute instance-templates create $IT_1_NAME \
 --custom-vm-type=$IT_1_SERIES \
 --tags=$TARGET_TAGS \
 --network=$NETWORK_NAME \
 --subnet=$SUBNET_A_NAME \
 --metadata=$METADATA_1


gcloud compute instance-templates create $IT_2_NAME \
 --custom-vm-type=$IT_1_SERIES \
 --tags=$TARGET_TAGS \
 --network=$NETWORK_NAME \
 --subnet=$SUBNET_B_NAME \
 --metadata=$METADATA_1

gcloud compute instance-templates list

read -p  "Continue...\n" -s

############

echo "### Create Managed instance groups ###"


export IG_1_NAME=instance-group-1
export IG_2_NAME=instance-group-2

gcloud compute instance-groups managed create $IG_1_NAME \
 --template=$IT_1_NAME \
 --region=$REGION \
 --zone=$ZONE_1 \
 --size=1

gcloud compute instance-groups managed create $IG_2_NAME \
 --template=$IT_2_NAME \
 --region=$REGION \
 --zone=$ZONE_2 \
 --size=1

gcloud compute instance-groups managed set-autoscaling $IG_1_NAME \
 --max-num-replicas=5 \
 --target-cpu-utilization=80 \
 --cool-down-period=45


gcloud compute instance-groups managed set-autoscaling $IG_2_NAME \
 --max-num-replicas=5 \
 --target-cpu-utilization=80 \
 --cool-down-period=45

gcloud compute instance-groups managed list


read -p  "Continue...\n" -s

############

echo "### Create health check ###"

export HC_NAME=my-ilb-health-check

gcloud compute health-checks create http $HC_NAME \
 --port=80 \
 --protocol=TCP

echo "### Create backends ###"

export BE_SERVICE_NAME=my-backend-service

gcloud compute backend-services create $BE_SERVICE_NAME \
 --global

gcloud compute backend-service add-backend $BE_SERVICE_NAME \
 --instance-group=$IG_1_NAME

gcloud compute backend-service add-backend $BE_SERVICE_NAME \
 --instance-group=$IG_2_NAME

echo "### Create IP address ### "

export IP_ADDRESS_NAME=my-ilb-ip

gcloud compute addresses create $IP_ADDRESS_NAME \
 --addres=10.10.30.5 

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

