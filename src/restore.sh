#! /bin/sh

set -e
set -o pipefail

source ./env.sh

# Function to list available backups
list_backups() {
    echo "Fetching available backups from S3..."
    aws $aws_args s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" | grep "PRE" | awk '{print $2}' | sed 's/\\/\///' | sort -r
}

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: /restore.sh <TIMESTAMP> [DATABASE_NAME]"
    echo ""
    echo "Available Backups:"
    list_backups
    exit 1
fi

TIMESTAMP="$1"
DB_NAME="$2"

S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${TIMESTAMP}"

# Verify backup exists
echo "Verifying backup at $S3_PATH..."
if ! aws $aws_args s3 ls "$S3_PATH" > /dev/null; then
    echo "❌ Backup path not found: $S3_PATH"
    echo "Available Backups:"
    list_backups
    exit 1
fi

# Function to restore a single database
restore_database() {
    local db=$1
    local file_path="/tmp/${db}.sql.gz"
    local s3_file="${S3_PATH}/${db}.sql.gz"

    echo "----------------------------------------------------------------"
    echo "🔄 Processing Database: $db"
    echo "----------------------------------------------------------------"

    # Download
    echo "⬇️  Downloading $s3_file..."
    if ! aws $aws_args s3 cp "$s3_file" "$file_path"; then
        echo "❌ Could not download backup file for $db. Skipping."
        return 1
    fi

    # Decrypt if needed
    if [ -n "${PASSPHRASE:-}" ]; then
        echo "🔐 Decrypting..."
        gpg --decrypt --batch --passphrase "$PASSPHRASE" "$file_path" > "${file_path}.dec"
        rm "$file_path"
        file_path="${file_path}.dec"
    fi

    # Drop and Create
    echo "🗑️  Dropping database $db..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "DROP DATABASE IF EXISTS \
`$db`\";"
    
    echo "✨ Creating database $db..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "CREATE DATABASE \
`$db`\";"

    # Restore
    echo "🚀 Restoring data..."
    if [ "${file_path##*.}" = "gz" ]; then
        zcat "$file_path" | mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" "$db"
    else
        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" "$db" < "$file_path"
    fi

    echo "✅ Restore of $db complete!"
    rm "$file_path"
}

if [ -z "$DB_NAME" ] || [ "$DB_NAME" = "all" ]; then
    echo "📜 Restoring ALL databases from $TIMESTAMP..."
    
    # Get list of .sql.gz files in that S3 directory
    dumps=$(aws $aws_args s3 ls "$S3_PATH/" | grep ".sql.gz" | awk '{print $4}' | sed 's/.sql.gz//')
    
    for db in $dumps; do
        restore_database "$db"
    done
else
    restore_database "$DB_NAME"
fi

echo "🎉 All requested restores completed."