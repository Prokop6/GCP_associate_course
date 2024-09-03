export BUCKET_NAME=qwiklabs-gcp-01-cf1e9cc5d1db-bucket

echo "Setting bucket name to $BUCKET_NAME"

export REGION=us-west1
echo "Setting REGION to $REGION"

export ZONE=us-west1-a
echo "Setting ZONE to $ZONE"

export TOPIC_NAME=topic-memories-548
echo "Setting TOPIC_NAME to $TOPIC_NAME"

export CLOUD_FUNCTION_NAME=memories-thumbnail-maker
echo "Setting CLOUD_FUNCTION_NAME to $CLOUD_FUNCTION_NAME"


echo "Creating bucket..."


gcloud storage buckets create gs://$BUCKET_NAME \
  --location=$REGION

gcloud storage buckets list

echo "Creating topic..."

gcloud pubsub topics create $TOPIC_NAME

gcloud pubsub topics list 

echo "Creating cloud function..."

gcloud functions deploy $CLOUD_FUNCTION_NAME \
 --gen2 \
 --runtime=nodejs20 \
 --region=$REGION \
 --source=src \
 --entry-point=$CLOUD_FUNCTION_NAME \
 --trigger-bucket=$BUCKET_NAME \
 --run-service-account=qwiklabs-gcp-01-cf1e9cc5d1db@qwiklabs-gcp-01-cf1e9cc5d1db.iam.gserviceaccount.com


## The function above did not work fully - an http trigger was created instead of the bucket related trigger, some additional parameters may been missing 


gcloud functions list
