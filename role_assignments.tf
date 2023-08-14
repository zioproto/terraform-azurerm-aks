resource "azurerm_role_assignment" "acr" {
  for_each = var.attached_acr_id_map

  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  scope                            = each.value
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}

# The AKS cluster identity has the Contributor role on the AKS second resource group (MC_myResourceGroup_myAKSCluster_eastus)
# However when using a custom VNET, the AKS cluster identity needs the Network Contributor role on the VNET subnets
# used by the system node pool and by any additional node pools.
# https://learn.microsoft.com/en-us/azure/aks/configure-kubenet#prerequisites
# https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni#prerequisites
# https://github.com/Azure/terraform-azurerm-aks/issues/178
resource "azurerm_role_assignment" "network_contributor" {
  for_each = var.create_role_assignment_network_contributor && (var.client_id == "" || var.client_secret == "") ? local.subnet_ids : []

  principal_id         = coalesce(try(data.azurerm_user_assigned_identity.cluster_identity[0].principal_id, azurerm_kubernetes_cluster.main.identity[0].principal_id), var.client_id)
  scope                = each.value
  role_definition_name = "Network Contributor"

  lifecycle {
    precondition {
      condition     = length(var.network_contributor_role_assigned_subnet_ids) == 0
      error_message = "Cannot set both of `var.create_role_assignment_network_contributor` and `var.network_contributor_role_assigned_subnet_ids`."
    }
  }
}

resource "azurerm_role_assignment" "network_contributor_on_subnet" {
  for_each = var.network_contributor_role_assigned_subnet_ids

  principal_id         = coalesce(try(data.azurerm_user_assigned_identity.cluster_identity[0].principal_id, azurerm_kubernetes_cluster.main.identity[0].principal_id), var.client_id)
  scope                = each.value
  role_definition_name = "Network Contributor"

  lifecycle {
    precondition {
      condition     = !var.create_role_assignment_network_contributor
      error_message = "Cannot set both of `var.create_role_assignment_network_contributor` and `var.network_contributor_role_assigned_subnet_ids`."
    }
  }
}

resource "azurerm_role_assignment" "application_gateway_subnet_network_contributor" {
  count = (var.ingress_application_gateway_enabled && var.ingress_application_gateway_subnet_id != null) ? 1 : 0

  principal_id         = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  scope                = var.ingress_application_gateway_subnet_id
  role_definition_name = "Network Contributor"
}