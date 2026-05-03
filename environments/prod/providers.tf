terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
    # All other values supplied via -backend-config at init time
  }
}

provider "azurerm" {
  features {}
}
