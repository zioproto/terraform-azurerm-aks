resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  name     = coalesce(var.resource_group_name, "${random_id.prefix.hex}-rg")
  location = var.location
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
    location = var.location
  }
}

data "null_data_source" "resource_group" {
  inputs = {
    name = local.resource_group.name
  }
}

resource "azurerm_virtual_network" "test" {
  name                = "${random_id.prefix.hex}-vn"
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "test" {
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = local.resource_group.name
  virtual_network_name                           = azurerm_virtual_network.test.name
  address_prefixes                               = ["10.52.0.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

module "aks_without_monitor" {
  source                           = "../.."
  prefix                           = "prefix2-${random_id.prefix.hex}"
  resource_group_name              = local.resource_group.name
  disk_encryption_set_id           = azurerm_disk_encryption_set.des.id
  enable_role_based_access_control = true
  private_cluster_enabled          = true
  rbac_aad_managed                 = true
  admin_username                   = null
#checkov:skip=CKV_AZURE_4:The logging is turn off for demo purpose. DO NOT DO THIS IN PRODUCTION ENVIRONMENT!
  enable_log_analytics_workspace   = false
  net_profile_pod_cidr             = "10.1.0.0/16"
}