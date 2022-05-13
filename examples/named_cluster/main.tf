provider "azurerm" {
  features {}
}

resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  name     = coalesce(var.resource_group_name, "${random_id.prefix.hex}-rg")
  location = var.location
}

data "null_data_source" "resource_group" {
  inputs = {
    name = azurerm_resource_group.main.name
  }

  depends_on = [azurerm_resource_group.main]
}


resource "azurerm_virtual_network" "test" {
  name                = "${random_id.prefix.hex}-vn"
  address_space       = ["10.52.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "test" {
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.test.name
  address_prefixes                               = ["10.52.0.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_user_assigned_identity" "test" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${random_id.prefix.hex}-identity"
}

module "aks_cluster_name" {
  source                               = "../.."
  cluster_name                         = "test-cluster"
  prefix                               = "prefix"
  resource_group_name                  = data.null_data_source.resource_group.outputs["name"]
  enable_log_analytics_workspace       = true
  cluster_log_analytics_workspace_name = "test-cluster"
  enable_kube_dashboard                = false
  net_profile_pod_cidr                 = "10.1.0.0/16"
  identity_type                        = "UserAssigned"
  user_assigned_identity_id            = azurerm_user_assigned_identity.test.id
}