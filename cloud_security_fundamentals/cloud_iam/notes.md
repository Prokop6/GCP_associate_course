# Cloud IAM

## Initial setup

```shell
gcloud auth login --cred-file creds.json
export PROJECT=qwiklabs-gcp-03-9355a5d4f3f1

gcloud config set project $PROJECT

export USER_2_ID=student-03-33502c06dbdb@qwiklabs.net

export BUCKET_NAME=$PROJECT-2024-09-04

```

## Create the bucket

specs: 

* multi-regional
* prevent public access

```shell
gcloud storage buckets create gs://$BUCKET_NAME \
 --location=US \
 --public-access-prevention
```

### Create and upload random file

```shell
echo "Hello, World\!" >> file.txt

gsutil cp ./file.txt gs://$BUCKET_NAME/sample.txt
```

## Remove user 2's access to project

remove project viewer role ()

```shell
gcloud projects remove-iam-policy-binding $PROJECT \
--member=user:$USER_2_ID \
--role=roles/viewer
```

this did work properly (Access was revoked) but quicklabs complained about finding no logs that support the access revocation, hat to add and re-revoke the privilages by GUI (??)

## Test access as User 2

User 2 should have no access at all

## Grant new role to user 2

role to be granted **storage object viewer**: `roles/storage.objectViewer`


```shell
gcloud storage buckets add-iam-policy-binding $BUCKET \
--member=user:$USER_2_ID \
--role=roles/storage.objectViewer
```

initial attempt (above) was wrong, the privilages have to be granted on the project level, not the individual bucket

```shell
gcloud projects add-iam-policy-binding $PROJECT \
--member=user:$USER_2_ID \
--role=roles/storage.objectViewer
```

### Test access as User 2

User 2 should have direct access to the bucket object, but not to the project itself. 

this worked correctly

## Remove the new privilages

```shell
gcloud projects remove-iam-policy-binding $PROJECT \
--member=user:$USER_2_ID \
--role=roles/storage.objectViewer
```

### Test

this again did work in practice, but not for quiclabs; 

log analysis shows that the main service account was responsible for the GUI changes, whers the student account for the gcloud changes; this was probably the cause of the issue - did not test due to lab shutdown
