#!/bin/bash

# PostgreSQL restore settings
PG_HOST="localhost"  # update if required
PG_PORT="1234"   # update
PG_DB_NAME="tfe_database"  # update
PG_USER="tfe_user"        # update
PG_PASSWORD="your_secure_password"  # Update

# Azure Blob Storage settings
STORAGE_ACCOUNT_NAME="tfebackupsa"  # update
CONTAINER_NAME="tfe-backups" 
SAS_TOKEN="your_sas_token"  #update
BLOB_NAME="postgres-backup-latest.sql"  # update
BACKUP_DIR="/var/backups/tfe"  #update if required
DOWNLOAD_FILE="${BACKUP_DIR}/$BLOB_NAME"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Download the backup from Azure Blob Storage
az storage blob download \
  --account-name $STORAGE_ACCOUNT_NAME \
  --container-name $CONTAINER_NAME \
  --name $BLOB_NAME \
  --file $DOWNLOAD_FILE \
  --sas-token "$SAS_TOKEN"

# Check if the download was successful
if [[ $? -ne 0 ]]; then
  echo "Failed to download the backup from Azure Blob Storage!"
  exit 1
fi

echo "Backup downloaded successfully: $DOWNLOAD_FILE"

# Restore the PostgreSQL database from the backup
PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB_NAME -f $DOWNLOAD_FILE

# Check if the restore was successful
if [[ $? -ne 0 ]]; then
  echo "PostgreSQL restore failed!"
  exit 1
fi

echo "PostgreSQL restore completed successfully."
