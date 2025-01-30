module "tfe_backup" {
  source              = "./tfe-backup-module"
  resource_group_name = "tfe-backup-rg"
  location           = "East US"
  storage_account_name = "tfebackupsa"
  container_name      = "tfe-backups"
  tfe_instance_ip     = "0.0.0.0" #update
  ssh_user            = "user name" #update
  ssh_private_key     = "ssh key location" #update
}
