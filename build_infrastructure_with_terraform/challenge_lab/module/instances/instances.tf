variable "name" {}

variable "vpc_network_name" {
    type = string
    default = "default"
}
variable "subnet" {
    type = string
    default = ""
}

resource "google_compute_instance" "vm" {
    
    name    =   var.name
    machine_type = var.machine_type
    zone         = var.zone
    
    metadata_startup_script    =   <<-EOT
        #!/bin/bash
    EOT
    
    allow_stopping_for_update = true

  boot_disk {
    
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

   
    network_interface {
        network =   var.vpc_network_name

        
        #subnetwork = var.subnet
    }
}
