# IAM Custom Roles

## Basic setup

```shell
gcloud auth login --cred-file creds.json

export PROJECT=qwiklabs-gcp-01-b6833eff5ea0
export DEVSHELL_PROJECT_ID=$PROJECT

gcloud config set project $PROJECT

```

## Get info on roles

### View available permissions 

```shell
gcloud iam list-testable-permissions \
  //cloudresourcemanager.googleapis.com/projects/$DEVSHELL_PROJECT_ID
```

### Get role metadata

```shell
gcloud iam roles describe roles/viewer

gcloud iam roles describe roles/editor

```

### List roles grantable to resource

```shell
gcloud iam list-grantable-roles \
//cloudresourcemanager.googleapis.com/projects/$DEVSHELL_PROJECT_ID
```

## Create a custom role

the `iam.roles.create` permission is required for a non-owner role creating user

when creating roles either `--organization` or `--project` must be set

### defining role with yaml

```yaml
title: abc
description: abc
stage: (lunch stage ALPHA/BETA/GA/etc)
include permissions:
- abc
- def
```

```bash
cat << 'EOF' >> role-definition.yaml
title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete

EOF

cat role-definition.yaml
```

```bash
export ROLE_1_NAME=editor
export ROLE_2_NAME=viewer
```

```bash
gcloud iam roles create $ROLE_1_NAME --project $PROJECT \
  --file role-definition.yaml
```

#### Test progress

### Define role with flags

```shell
gcloud iam roles create $ROLE_2_NAME --project $DEVSHELL_PROJECT_ID \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA
```

#### Test progress

## Modify exising roles

an `etag` value for all roles prevents performing simultanious changes of a role, that could fail

the `describe` command returns yaml formatted data that can be used as basis for role modification

### Get role details

```shell
gcloud iam roles describe $ROLE_1_NAME \
 --project $PROJECT | tee new-role-definition.yaml
```

### Update with file

add 

```yaml
- storage.buckets.get
- storage.buckets.list
```

to `includePermissions`

update role:

```shell
gcloud iam roles update $ROLE_1_NAME \
 --project $PROJECT \
 --file new-role-definition.yaml
```

#### Test

### Update with flags

flags `--add-permissions` and `--remove-permissions` can be used to modify the roles

```shell
gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--add-permissions storage.buckets.get,storage.buckets.list
```

## Disabeling roles

when a roles `stage` is set to `DISABLED` the privilages of the role are not granted

```shell
gcloud iam roles update $ROLE_2_NAME \
 --project $PROJECT \
 --stage DISABLED
```

### Test

## Removing roles

a good practice is to set stage to `DEPRECATED` prior to removing it entirely

deleting role:

```shell
gcloud iam roles delete $ROLE_2_NAME \
 --project $PROJECT
```

the role can be un-deleted up to 7 days after its deletion

```shell
gcloud iam roles undelete $ROLE_2_NAME \
 --project $PROJECT
```

after 37 days the role ID is available for usage again

### Test 


