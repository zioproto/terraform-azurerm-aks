variable "location" {
  default = "eastus"
}

variable "client_id" {}
variable "client_secret" {}

variable "resource_group_name" {
  type    = string
  default = null
}