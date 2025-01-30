terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "tfe" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "tfe_backup" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfe.name
  location                 = azurerm_resource_group.tfe.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Blob Container for Backups
resource "azurerm_storage_container" "tfe_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfe_backup.name
  container_access_type = "private"
}

# SAS Token for Secure Access
resource "azurerm_storage_account_sas" "backup_sas" {
  connection_string = azurerm_storage_account.tfe_backup.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob = true
  }

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
  }

}

# Deploy Backup Script to TFE Instance
resource "null_resource" "deploy_backup_script" {
  provisioner "file" {
    source      = "${path.module}/scripts/tfe-backup.sh"
    destination = "/usr/local/bin/tfe-backup.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/tfe-restore.sh"
    destination = "/usr/local/bin/tfe-restore.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/bin/tfe-backup.sh",
      "chmod +x /usr/local/bin/tfe-restore.sh",
      "echo '0 0 * * * /usr/local/bin/tfe-backup.sh' | crontab -"
    ]
  }

  connection {
    type        = "ssh"
    host        = var.tfe_instance_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

# Output the results

output "resource_group_name" {
value = azurerm_resource_group.tfe_backup.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfe_backup.name
}

output "container_name" {
  value = azurerm_storage_container.tfe_container.name
}

output "sas_token" {
  value     = azurerm_storage_account_sas.backup_sas.sas
  sensitive = true
}
