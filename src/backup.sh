#! /bin/sh

set -e
set -o pipefail

source ./env.sh

# Use dashes for timestamp to be S3/path friendly
timestamp=$(date +"%Y-%m-%dT%H-%M-%S")
backup_parent_dir="/tmp/backups"
backup_dir="${backup_parent_dir}/${timestamp}"

mkdir -p "$backup_dir"

echo "Fetching database list from $MYSQL_HOST..."
if [ "$MYSQL_DATABASE" = "all" ] || [ -z "$MYSQL_DATABASE" ]; then
    # List all databases except internal ones
    dbs=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "SHOW DATABASES;" -s --skip-column-names | grep -Ev "^(information_schema|performance_schema|mysql|sys)$")
else
    dbs=$MYSQL_DATABASE
fi

if [ -z "$dbs" ]; then
    echo "No databases found!"
    exit 1
fi

echo "Found databases: $(echo $dbs | tr '\n' ' ')"

for db in $dbs; do
  echo "Backing up database: $db..."
  mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" $MYSQLDUMP_EXTRA_OPTS "$db" | gzip > "$backup_dir/${db}.sql.gz"
done

if [ -n "${PASSPHRASE:-}" ]; then
  echo "Encrypting backups..."
  for file in "$backup_dir"/*;
  do
    gpg --symmetric --batch --passphrase "$PASSPHRASE" "$file"
    rm "$file"
  done
fi

echo "Uploading backups to s3://${S3_BUCKET}/${S3_PREFIX}/${timestamp}/"...
aws $aws_args s3 cp "$backup_dir" "s3://${S3_BUCKET}/${S3_PREFIX}/${timestamp}/" --recursive

echo "Cleaning up local files..."
rm -rf "$backup_parent_dir"

echo "Backup complete."

# Retention logic
if [ -n "${BACKUP_KEEP_DAYS:-}" ]; then
  sec=$((86400*BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
  backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $S3_BUCKET older than $date_from_remove..."
  aws $aws_args s3api list-objects \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}" \
    --query "${backups_query}" \
    --output text \
    | xargs -r -n1 -t -I 'KEY' aws $aws_args s3 rm s3://"${S3_BUCKET}"/'KEY'
  echo "Removal complete."
fi
