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

module "aks_without_monitor" {
  source                         = "../.."
  prefix                         = "prefix2-${random_id.prefix.hex}"
  resource_group_name            = data.null_data_source.resource_group.outputs["name"]
  enable_log_analytics_workspace = false
  enable_kube_dashboard          = false
  net_profile_pod_cidr           = "10.1.0.0/16"
}