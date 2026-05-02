terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # Values supplied via -backend-config at init time
    # Keeps storage account name and key out of source control
  }
}

provider "azurerm" {
  features {}
}
