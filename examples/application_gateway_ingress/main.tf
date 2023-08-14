resource "random_id" "prefix" {
  byte_length = 8
}

resource "random_id" "name" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "${random_id.prefix.hex}-rg")
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
    location = var.location
  }
}

resource "azurerm_virtual_network" "test" {
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "test" {
  address_prefixes                               = ["10.52.0.0/24"]
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = local.resource_group.name
  virtual_network_name                           = azurerm_virtual_network.test.name
}

resource "azurerm_subnet" "appgw" {
  address_prefixes                               = ["10.52.1.0/24"]
  name                                           = "${random_id.prefix.hex}-gw"
  resource_group_name                            = local.resource_group.name
  virtual_network_name                           = azurerm_virtual_network.test.name
}

# Locals block for hardcoded names
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.test.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"
}

resource "azurerm_public_ip" "pip" {
  name                = "appgw-pip"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "ingress"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
  lifecycle {
    ignore_changes = [
#      tags,
#      backend_address_pool,
#      backend_http_settings,
#      http_listener,
#      probe,
#      request_routing_rule,
    ]
  }
}
resource azurerm_role_assignment "appgw1" {
  scope                = azurerm_resource_group.main[0].id
  role_definition_name = "Reader"
  principal_id         = module.aks.ingress_application_gateway.ingress_application_gateway_identity[0].object_id
}

resource azurerm_role_assignment "appgw2" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = module.aks.ingress_application_gateway.ingress_application_gateway_identity[0].object_id
}

module "aks" {
  source = "../.."

  prefix                    = random_id.name.hex
  resource_group_name       = local.resource_group.name
  kubernetes_version        = "1.26" # don't specify the patch version!
  automatic_channel_upgrade = "patch"
  agents_availability_zones = ["1", "2"]
  agents_count              = null
  agents_max_count          = 2
  agents_max_pods           = 100
  agents_min_count          = 1
  agents_pool_name          = "testnodepool"
  agents_pool_linux_os_configs = [
    {
      transparent_huge_page_enabled = "always"
      sysctl_configs = [
        {
          fs_aio_max_nr               = 65536
          fs_file_max                 = 100000
          fs_inotify_max_user_watches = 1000000
        }
      ]
    }
  ]
  agents_type          = "VirtualMachineScaleSets"
  azure_policy_enabled = true
  enable_auto_scaling                     = true
  enable_host_encryption                  = true
  http_application_routing_enabled        = true
  ingress_application_gateway_enabled     = true
#  ingress_application_gateway_name        = "${random_id.prefix.hex}-agw"
#  ingress_application_gateway_subnet_cidr = "10.52.1.0/24"
  ingress_application_gateway_id = azurerm_application_gateway.appgw.id
  local_account_disabled                  = false
  log_analytics_workspace_enabled         = true
  cluster_log_analytics_workspace_name    = random_id.name.hex
  maintenance_window = {
    allowed = [
      {
        day   = "Sunday",
        hours = [22, 23]
      },
    ]
    not_allowed = [
      {
        start = "2035-01-01T20:00:00Z",
        end   = "2035-01-01T21:00:00Z"
      },
    ]
  }
  net_profile_dns_service_ip        = "10.0.0.10"
  net_profile_service_cidr          = "10.0.0.0/16"
  network_plugin                    = "azure"
  network_policy                    = "azure"
  os_disk_size_gb                   = 60
  private_cluster_enabled           = false
  public_network_access_enabled     = true
  rbac_aad                          = true
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  vnet_subnet_id                    = azurerm_subnet.test.id
  depends_on = [
    azurerm_subnet.test,
  ]
}

resource "local_file" "kubeconfig" {
  filename = "kubeconfig"
  content = module.aks.kube_admin_config_raw
}