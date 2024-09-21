provider "google" {
    project = var.project-id
    region  = var.region
    zone    =   var.zone
}

terraform {
    required_providers {
        google  =   {
            source  =   "hashicorp/google"
            version = "< 5.0, >= 3.83"
            }
    }

    /*
    backend "gcp" {
        bucket  = var.bucket_name
        prefix  = "terraform/state"
  }

  */
}

/*
module var.bucket_name {
    source  =   "./module/storage"

    name    =   var.bucket-name
}

module  "tf-instance-1" {
    source  =   "./module/instances"
    
    name    =   "tf-instance-1"
    zone    =   var.zone

    network = default
    # network = network.network_name
   # subnet = subnet-01

}

module  "tf-instance-2" {
    source  =   "./module/instances"

    name    =   "tf-instance-2"
    zone    =   var.zone

    network = default

    #network = network.network_name
   # subnet = "subnet-02"
}

*/

/*


module  var.tf-instance-3-name {
    source  =   "./module/instances"

    name    =   var.tf-instance-3-name
    zone    =   var.zone
}

*/

