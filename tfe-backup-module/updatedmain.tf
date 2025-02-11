terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfe_backup" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfe_backup" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfe_backup.name
  location                 = azurerm_resource_group.tfe_backup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfe_backup" {
  name                  = "tfe-backups"
  storage_account_name  = azurerm_storage_account.tfe_backup.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "tfe_backup" {
  name                   = "tfe-backup.tar.gz"
  storage_account_name   = azurerm_storage_account.tfe_backup.name
  storage_container_name = azurerm_storage_container.tfe_backup.name
  type                   = "Block"
  source                 = var.backup_file_path
}

variable "resource_group_name" {}
variable "location" {}
variable "storage_account_name" {}
variable "backup_file_path" {}

output "backup_blob_url" {
  value = azurerm_storage_blob.tfe_backup.url
}
