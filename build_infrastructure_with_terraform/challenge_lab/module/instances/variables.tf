variable "region" {
    type    =   string
}

variable "zone" {
    type    =   string
}

variable "project_id" {
    type    =   string
}

variable    "machine_type"  {
    type    =   string
    default =   "e2-micro"
}

variable "name" {}

variable "network_name" {
    type = string
    default = "default"
}

variable "subnet_name" {
    type = string
    default = "default"
}