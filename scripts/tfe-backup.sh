#!/bin/bash

# Set the date format for the backup file name
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# PostgreSQL backup settings
PG_HOST="localhost"  # update if required
PG_PORT="1234"       # update
PG_DB_NAME="tfe_database"  # update
PG_USER="tfe_user"        # update
PG_PASSWORD="your_secure_password"  # update
BACKUP_DIR="/var/backups/tfe"  # update if required
PG_DUMP_FILE="${BACKUP_DIR}/tfe-backup-${DATE}.sql"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create PostgreSQL dump
PGPASSWORD=$PG_PASSWORD pg_dump -h $PG_HOST -p $PG_PORT -U $PG_USER $PG_DB_NAME > $PG_DUMP_FILE

# Check if the backup was successful
if [[ $? -ne 0 ]]; then
  echo "PostgreSQL backup failed!"
  exit 1
fi

echo "PostgreSQL backup successful: $PG_DUMP_FILE"

# Azure Blob Storage settings
STORAGE_ACCOUNT_NAME="tfebackupsa"  # update
CONTAINER_NAME="tfe-backups"  #
SAS_TOKEN="your_sas_token"  # update
BLOB_NAME="postgres-backup-${DATE}.sql"  #

# Upload the backup to Azure Blob Storage
az storage blob upload \
  --account-name $STORAGE_ACCOUNT_NAME \
  --container-name $CONTAINER_NAME \
  --file $PG_DUMP_FILE \
  --name $BLOB_NAME \
  --sas-token "$SAS_TOKEN"

# Check if the upload was successful
if [[ $? -ne 0 ]]; then
  echo "Backup upload to Azure Blob failed!"
  exit 1
fi

echo "Backup successfully uploaded to Azure Blob Storage: $BLOB_NAME"

