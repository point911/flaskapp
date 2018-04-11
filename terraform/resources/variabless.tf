variable "account_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
}

variable "gce_project" {
  description = "Project ID"
}

variable "gce_region_1" {
  default= "us-east1"
}

variable "gce_region_1_zone" {
  default= "b"
}

variable "gce_region_2" {
  default= "us-east1"
}

variable "gce_region_2_zone" {
  default= "c"
}

variable "vpc_name" {
  default = "ableto"
}

variable "vpc_network_name" {
  default = "ableto-vpc"
}

variable "app1_subnet_name" {
  default = "ableto-app-1"
}

variable "app2_subnet_name" {
  default = "ableto-app-2"
}

variable "app1_subnet_cidr" {
  default = "10.10.0.0/24"
}

variable "app2_subnet_cidr" {
  default = "10.10.1.0/24"
}

variable "internal_net" {
  default = "10.0.0.0/8"
}

variable "web_app_image" {
  default = "flask-app-image"
}

variable "instance_template_name" {
  default = "flask-app-template"
}

variable "prexisted_disk_name" {
  default = "flask-persistent-storage"
}

variable "firewall_networks" {
  description = "Name of the networks to create firewall rules in"
  type        = "list"
  default     = ["ableto-vpc"]
}