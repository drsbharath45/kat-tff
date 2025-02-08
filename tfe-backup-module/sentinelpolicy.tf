provider "azurerm" {
  features {}
}

module "resource_group" {
  source  = "terraform-azurerm-modules/resource-group/azurerm"
  name    = "tfe-backup-rg"
  location = "East US"
}

module "storage" {
  source                  = "terraform-azurerm-modules/storage-account/azurerm"
  name                    = "tfebackupstorage"
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

module "storage_container" {
  source                 = "terraform-azurerm-modules/storage-container/azurerm"
  name                   = "tfe-backups"
  storage_account_name   = module.storage.name
  container_access_type  = "private"
}

module "storage_blob" {
  source                 = "terraform-azurerm-modules/storage-blob/azurerm"
  name                   = "tfe-backup-latest.tar.gz"
  storage_account_name   = module.storage.name
  storage_container_name = module.storage_container.name
  type                   = "Block"
}

module "service_plan" {
  source                 = "terraform-azurerm-modules/service-plan/azurerm"
  name                   = "tfe-backup-restore-plan"
  location               = module.resource_group.location
  resource_group_name    = module.resource_group.name
  os_type                = "Linux"
  sku_name               = "Y1"
}

module "function_app" {
  source                      = "terraform-azurerm-modules/function-app/azurerm"
  name                        = "tfe-backup-restore-func"
  location                    = module.resource_group.location
  resource_group_name         = module.resource_group.name
  storage_account_name        = module.storage.name
  storage_account_access_key  = module.storage.primary_access_key
  app_service_plan_id         = module.service_plan.id
}

module "sentinel_policy" {
  source               = "terraform-azurerm-modules/sentinel-policy/azurerm"
  name                 = "tfe-sentinel-policy"
  resource_group_name  = module.resource_group.name
  policy_definition    = "custom-policy-definition"
}

output "storage_account_name" {
  value = module.storage.name
}

output "backup_container_url" {
  value = module.storage_container.name
}

output "sentinel_policy_name" {
  value = module.sentinel_policy.name
}
