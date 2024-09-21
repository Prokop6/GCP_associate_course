provider "google" {
    project = var.project_id
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
    backend "gcs" {
        #bucket  = #BUCKET NAME, NO variables
        prefix  = "terraform/state"
    }

    */

}

/*
module "backend_bucket" {
    source  =   "./module/storage"

    project_id = var.project_id
    region = var.region
    zone = var.zone

    name    =   var.bucket_name
}
*/


module  "tf-instance-1" {
    source  =   "./module/instances"
    
    project_id = var.project_id
    
    name    =   "tf-instance-1"
    region = var.region
    zone    =   var.zone
    
    #machine_type = var.machine_type

    #network_name = module.network.network_name
    #subnet_name = "subnet-01"

}

module  "tf-instance-2" {
    source  =   "./module/instances"
    
    project_id =  var.project_id

    name    =   "tf-instance-2"
    region  =   var.region
    zone    =   var.zone

    #machine_type = var.machine_type

   #network_name = module.network.network_name
   #subnet_name = "subnet-02"
}


# The module name must be the same as the new instance name, and variables cannot be used - it has to be hardcoded specificly for the run

/*


module  "tf-instance-3" {
    source  =   "./module/instances"

    project_id = var.project_id
    region = var.region
    zone    =   var.zone

    machine_type = var.machine_type 

    name    =   var.tf_instance_3_name
}

*/

