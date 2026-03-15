# MySQL S3 Backup

Docker container that periodically backups MySQL databases to S3-compatible storage.

## Features

- Backup all or specific databases.
- Periodically backup using `go-cron`.
- Upload to S3 (AWS, MinIO, etc.).
- Retention policy (delete old backups).
- Encryption with GPG.
- Restore script included.

## Usage

### Docker Compose

```yaml
services:
  backup:
    image: ghcr.io/ahmedashraf093/mysql-s3-backup:latest
    environment:
      - SCHEDULE=@daily
      - MYSQL_HOST=mysql_service
      - MYSQL_USER=root
      - MYSQL_PASSWORD=password
      - S3_ACCESS_KEY_ID=minioadmin
      - S3_SECRET_ACCESS_KEY=password
      - S3_BUCKET=my-backups
      - S3_PREFIX=mysql
      - S3_ENDPOINT=https://s3.example.com
      - BACKUP_KEEP_DAYS=7
```

### Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `MYSQL_DATABASE` | Database name to backup. Use `all` for all databases. | `all` |
| `MYSQL_HOST` | MySQL host. | |
| `MYSQL_PORT` | MySQL port. | `3306` |
| `MYSQL_USER` | MySQL user. | |
| `MYSQL_PASSWORD` | MySQL password. | |
| `S3_ACCESS_KEY_ID` | S3 access key. | |
| `S3_SECRET_ACCESS_KEY` | S3 secret key. | |
| `S3_BUCKET` | S3 bucket name. | |
| `S3_PREFIX` | Path prefix in the bucket. | `backup` |
| `S3_ENDPOINT` | S3 endpoint URL (for MinIO). | |
| `SCHEDULE` | Cron schedule (e.g. `@daily`, `0 0 * * *`). | |
| `BACKUP_KEEP_DAYS` | Number of days to keep backups. | |
| `PASSPHRASE` | GPG passphrase for encryption. | |

## Restore

To restore, run the `restore.sh` script inside the container:

```bash
docker exec <container_id> sh /restore.sh <TIMESTAMP> [DATABASE_NAME]
```