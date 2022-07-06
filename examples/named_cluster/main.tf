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

resource "azurerm_user_assigned_identity" "test" {
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  name                = "${random_id.prefix.hex}-identity"
}

module "aks_cluster_name" {
  source                               = "../.."
  cluster_name                         = "test-cluster"
  prefix                               = "prefix"
  resource_group_name                  = local.resource_group.name
  disk_encryption_set_id               = azurerm_disk_encryption_set.des.id
  enable_role_based_access_control     = true
  rbac_aad_managed                     = true
  enable_log_analytics_workspace       = true
  private_cluster_enabled              = true
  admin_username                       = null
  cluster_log_analytics_workspace_name = "test-cluster"
  net_profile_pod_cidr                 = "10.1.0.0/16"
  identity_type                        = "UserAssigned"
  identity_ids                         = [azurerm_user_assigned_identity.test.id]
}
