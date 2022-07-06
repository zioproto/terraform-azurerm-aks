variable "create_resource_group" {
  type     = bool
  default  = true
  nullable = false
}

variable "location" {
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "key_vault_firewall_bypass_ip_cidr" {
  type    = string
  default = null
}

variable "managed_identity_principal_id" {
  type    = string
  default = null
}