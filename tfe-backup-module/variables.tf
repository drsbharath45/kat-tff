variable "resource_group_name" {
  type        = string
  default     = "tfe-backup-rg"
}

variable "location" {
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  type        = string
  default     = "tfebackupsa"
}

variable "container_name" {
  type        = string
  default     = "tfe-backups"
}

variable "tfe_instance_ip" {
  type        = string
}

variable "ssh_user" {
  type        = string
  default     = "username"
}

variable "ssh_private_key" {
  type        = string
}

variable "postgres_db_name" {
  type        = string
}

variable "postgres_user" {
  type        = string
}

variable "postgres_password" {
  type        = string
  sensitive   = true
}
