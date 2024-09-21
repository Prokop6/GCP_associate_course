variable "region" {
    type    =   string
}

variable "zone" {
    type    =   string
}

variable "project_id" {
    type    =   string
}

variable "tf_instance_3_name" {
    type = string
    default = ""
}

variable "bucket_name" {
    type = string
}

variable "machine_type" {
    type = string
    default = ""
}

variable "vpc_network_name" {
    type = string
    default = "default"
}