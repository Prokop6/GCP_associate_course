resource "google_compute_instance" "vm" {

    project = var.project_id

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
        network =   var.network_name

  
        subnetwork = var.subnet_name
    }
}
