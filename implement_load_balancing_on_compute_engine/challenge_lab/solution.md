# Implement load balancing on Compute Engine - challenge lab

## Basic requirements

* use default REGION and ZONE
* resource name convention it `team_name-resource_name`
* instance templates should be global
* use e2-micro for linux, e2-medium for windows

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export REGION=
export ZONE=
export PROJECT=
export TEAM_NAME=nucleus

gcloud config set project $PROJECT
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

export MACHINE_TYPE_DEFAULT=e2-medium
export MACHINE_TYPE_LINUX=e2-micro

```

## Create a project jumphost instance

```shell

export INSTANCE_NAME_01=nucleus-jumphost-736
export INSTANCE_ZONE_01=$ZONE
export MACHINE_TYPE_01=e2-micro
export IMAGE_FAMILY_LINUX=debian-12

gcloud compute instances create $INSTANCE_NAME_01 \
--zone $ZONE \
--image-family $IMAGE_FAMILY_LINUX \
--image-project debian-cloud \
--machine-type $MACHINE_TYPE_LINUX

```

### Test

## Set up HTTP load balancer

a load balancer requires:

* instance template
* 1+n instance groups
* backend service with named ports
* health check
* fw rules for health check
* url map with default service
* target http proxy
* forwarding rules

### create instance template

```shell
export TEMPLATE_NAME=${TEAM_NAME}-nginx-template
export INSTANCE_GROUP_NAME=${TEAM_NAME}-nginx-group
export IMAGE_FAMILY=$IMAGE_FAMILY_LINUX

```

```shell
gcloud compute instance-templates create $TEMPLATE_NAME \
--machine-type $MACHINE_TYPE_DEFAULT \
--image-family $IMAGE_FAMILY \
--image-project debian-cloud \
--tags allow-http \
--global \
--metadata \
startup-script=cat << EOF > startup.sh

# ! /bin/bash

apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF
```

### create managed instance group

```shell
gcloud compute instance-groups managed create $INSTANCE_GROUP_NAME \
--template $TEMPLATE_NAME \
--region $REGION \
--size 2

gcloud compute instance-groups set-named-ports $INSTANCE_GROUP_NAME \
--named-ports http:80
```

### create firewall rule

```shell
export FIREWALL_RULE_NAME=

```

```shell
gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
--allow=tcp:80 \
--direction=INGRESS \
--target-tags=allow-http
```

### create health check

```shell
export HEALTH_CHECK_NAME=${TEAM_NAME}-http-health-check

```

```shell
gcloud compute health-checks create http $HEALTH_CHECK_NAME \
--global \
--enable-logging \
--check-interval 5 \
--timeout 5s \
--healthy-threshold 2 \
--unhealthy-threshold 2 \
--port 80

```

### create backend service

```shell
export BACKEND_SERVICE_NAME=$${TEAM_NAME}-nginx-http-service

```

```shell
gcloud compute backend-services create $BACKEND_SERVICE_NAME \
--health-checks=$HEALTH_CHECK_NAME \
--global

```

```shell
gcloud compute backend-service add-backend $BACKEND_SERVICE_NAME \
--instance-group $INSTANCE_GROUP_NAME \
--instance-group-region $REGION \
--global \
--balancing-mode "UTILIZATION"

```

### create url map

```shell
export URL_MAP_NAME=${TEAM_NAME}-nginx_url_map
```

```shell
gcloud compute url-maps create $URL_MAP_NAME \
--default-service $BACKEND_SERVICE_NAME \
--global
```

### create target http proxy

```shell
export HTTP_PROXY_NAME=${TEAM_NAME}-nginx_proxy

```

```shell
gcloud compute target-http-proxies create $HTTP_PROXY_NAME \
--url-map ${URL_MAP_NAME}

```

### create forwarding rule

```shell
export FORWARDING_RULE_NAME=${TEAM_NAME}-http_forwarding_rule

```

```shell
gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
--global \
--target-http-proxy $HTTP_PROXY_NAME \
--backend-service $BACKEND_SERVICE_NAME \
--load-balancing-scheme "EXTERNAL" \
--ports 80
```

### Test
