variable "name" {}

resource "google_storage_bucket" "bucket" {
    
    name    =   var.name
    force_destroy   = true
    location    =   "US"
    uniform_bucket_level_access =   true

}
