provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfe_backup" {
  name     = "tfe-backup-rg"
  location = "East US"
}

resource "azurerm_storage_account" "tfe_backup" {
  name                     = "tfebackupstorage"
  resource_group_name      = azurerm_resource_group.tfe_backup.name
  location                 = azurerm_resource_group.tfe_backup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfe_container" {
  name                  = "tfe-backups"
  storage_account_name  = azurerm_storage_account.tfe_backup.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "tfe_vault" {
  name                = "tfe-keyvault"
  location            = azurerm_resource_group.tfe_backup.location
  resource_group_name = azurerm_resource_group.tfe_backup.name
  tenant_id           = "your-tenant-id"
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "tfe_storage_key" {
  name         = "tfe-storage-key"
  value        = azurerm_storage_account.tfe_backup.primary_access_key
  key_vault_id = azurerm_key_vault.tfe_vault.id
}

resource "azurerm_virtual_machine" "tfe_vm" {
  name                  = "tfe-backup-vm"
  location              = azurerm_resource_group.tfe_backup.location
  resource_group_name   = azurerm_resource_group.tfe_backup.name
  network_interface_ids = ["/subscriptions/{subscription-id}/resourceGroups/tfe-backup-rg/providers/Microsoft.Network/networkInterfaces/{nic-id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "tfe-backup-vm"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "null_resource" "tfe_backup_script" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_virtual_machine.tfe_vm.public_ip_address
    }

    inline = [
      "echo 'Starting TFE Backup'",
      "export STORAGE_KEY=$(az keyvault secret show --name tfe-storage-key --vault-name ${azurerm_key_vault.tfe_vault.name} --query value -o tsv)",
      "tar -czvf /tmp/tfe-backup.tar.gz /var/lib/tfe",
      "az storage blob upload --account-name ${azurerm_storage_account.tfe_backup.name} --container-name tfe-backups --name tfe-backup-$(date +%F).tar.gz --file /tmp/tfe-backup.tar.gz --account-key $STORAGE_KEY"
    ]
  }
}
