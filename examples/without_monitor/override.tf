terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11.0"
    }
  }
}

module "aks_without_monitor" {
  source = "../../"
}