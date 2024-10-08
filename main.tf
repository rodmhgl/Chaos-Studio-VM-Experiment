terraform {
  required_providers {
    # 4.0+ is required as we are utilizing provider functions
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.8.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "02892755-eecf-4df8-bc08-a55279be6b35"
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "chaos-rg"
  location = "eastus"
}
