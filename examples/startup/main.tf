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

module "aks" {
  source                           = "../.."
  prefix                           = "prefix-${random_id.prefix.hex}"
  resource_group_name              = local.resource_group.name
  client_id                        = var.client_id
  client_secret                    = var.client_secret
  network_plugin                   = "azure"
  vnet_subnet_id                   = azurerm_subnet.test.id
  os_disk_size_gb                  = 60
  disk_encryption_set_id           = azurerm_disk_encryption_set.des.id
  enable_http_application_routing  = true
  enable_azure_policy              = true
  enable_host_encryption           = true
  enable_role_based_access_control = true
  rbac_aad_managed                 = true
  enable_log_analytics_workspace   = true
  sku_tier                         = "Paid"
  private_cluster_enabled          = true
  enable_auto_scaling              = true
  agents_min_count                 = 1
  agents_max_count                 = 2
  agents_count                     = null
  agents_max_pods                  = 100
  agents_pool_name                 = "testnodepool"
  agents_availability_zones        = ["1", "2"]
  agents_type                      = "VirtualMachineScaleSets"

  agents_labels = {
    "node1" : "label1"
  }

  agents_tags = {
    "Agent" : "agentTag"
  }

  enable_ingress_application_gateway      = true
  ingress_application_gateway_name        = "${random_id.prefix.hex}-agw"
  ingress_application_gateway_subnet_cidr = "10.52.1.0/24"

  network_policy                 = "azure"
  net_profile_dns_service_ip     = "10.0.0.10"
  net_profile_docker_bridge_cidr = "170.10.0.1/16"
  net_profile_service_cidr       = "10.0.0.0/16"
}
