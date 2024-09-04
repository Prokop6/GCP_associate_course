# Service Accounts and Roles

## Basic setup

```shell
gcloud auth login --cred-file ./creds.json

export PROJECT=qwiklabs-gcp-02-99b28e0e4250

gcloud config set project $PROJECT

gcloud config get project

export REGION=us-central1
export ZONE=us-central1-c

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
```

## Create service account 

(up to 100 per project - owner + google api + 98 custom defined)

```shell
export SA_NAME=my-sa-123
export SA_DISPLAY_NAME="my service account"

gcloud iam service-accounts create $SA_NAME \
 --display-name $SA_DISPLAY_NAME


gcloud iam service-accounts describe $SA_FULL_NAME
```

## Granting role to service account

```shell
export SA_FULL_NAME=${SA_NAME}@${PROJECT}.iam.gserviceaccount.com 

gcloud projects add-iam-policy-binding $PROJECT \
 --member serviceAccount:${SA_FULL_NAME}  \
 --role roles/editor
```

### TEST

## Access BigQuery with service acconut

### Create Service account

```shell
export BQ_SA_NAME=bigquery-qwiklab

export BQ_SA_FULL_NAME=${BQ_SA_NAME}@${PROJECT}.iam.gserviceaccount.com 

gcloud iam service-accounts create $BQ_SA_NAME 

gcloud projects add-iam-policy-binding $PROJECT \
 --member serviceAccount:$BQ_SA_FULL_NAME \
 --role roles/bigquery.dataViewer


gcloud projects add-iam-policy-binding $PROJECT \
 --member serviceAccount:$BQ_SA_FULL_NAME \
 --role roles/bigquery.user

```

### Create compute instance

```shell
gcloud compute instances create bigquery-instance \
 --zone $ZONE \
 --machine-type e2-medium \
 --image-project debian-cloud \
 --image-family debian-11 \
 --service-account $BQ_SA_FULL_NAME \
 --scopes bigquery
```

### Follow the course - BQ specific instructions
