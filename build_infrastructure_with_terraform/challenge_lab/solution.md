# Build Infrastructure with Terraform on Google Cloud: Challenge Lab

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json
export GOOGLE_APPLICATION_CREDENTIALS=creds.json

export PROJECT=
export REGION=
export ZONE=

export TF_VAR_project-id=$PROJECT
export TF_VAR_region=$REGION
export TF_VAR_zone=$ZONE

gcloud config set project $PROJECT

```

## Create configuration files

create basic config structure

```shell
touch main.tf
touch variables.tf

mkdir -p modules/instances
mkdir modules/storage

touch modules/instances/instances.tf
touch modules/instances/outputs.tf
touch modules/instances/variables.tf

touch modules/storage/storage.tf
touch modules/storage/outputs.ft
touch modules/storage/variables.tf

```

create the configurations as described

```shell
terraform init
terraform validate

```

## Import infrastructure

uncomment tf-instance-1 and tf-instance-2 in main.tf

```shell
terraform init

terraform import module.tf-instance-1.google_compute_instance.vm  $PROJECT/tf-instance-1
import module.tf-instance-2.google_compute_instance.vm $PROJECT/tf-instance-2

terraform apply

```

apply will cause to update machines in place

### Test

## Configure remote backend

uncomment bucket part from main.tf

```shell
terraform init

terraform plan -out tf_plan
terraform apply tf_plan

```

setup remote backend

uncomment backend "gcp" part in main.tf

```shell
export TF_VAR_bucket_name=

terraform init
terraform plan -o tf_plan

terraform apply tf_plan

```

### Test

## Modify and update infrastructure

```shell
export TF_VAR_machine_type=e2-standard-2
export TF_VAR_tf-instance-3-name=

```

uncomment module with 3rd instance

```shell
terraform init

terraform plan -o tf_plan
terraform apply tf_plan

```

### Test

## Destroy resources

re-comment tf-instance-3 in main.ft

```shell

terraform init
terraform plan -o tf_plan

terraform apply

```

### Test

## Use module from registry

defang network.tf_

```shell
terraform init
terraform plan -o tf_plan

terraform apply

```

uncomment sub-network from instance definition
swap networks in module instance declarations in main.tf
uncomment var.subnet from instance module calls in main.tf

```shell
terraform init
terraform plan -o tf_plan

terraform apply

```

### Test

## Configure firewall

defang firewall_rule.tf
