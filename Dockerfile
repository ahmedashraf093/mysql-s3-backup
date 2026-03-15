ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION}
ARG TARGETARCH

COPY src/install.sh install.sh
RUN sh install.sh && rm install.sh

ENV MYSQL_DATABASE=''
ENV MYSQL_HOST=''
ENV MYSQL_PORT=3306
ENV MYSQL_USER=''
ENV MYSQL_PASSWORD=''
ENV MYSQLDUMP_EXTRA_OPTS='--quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384'
ENV S3_ACCESS_KEY_ID=''
ENV S3_SECRET_ACCESS_KEY=''
ENV S3_BUCKET=''
ENV S3_REGION='us-east-1'
ENV S3_PREFIX='backup'
ENV S3_ENDPOINT=''
ENV S3_S3_FORCE_PATH_STYLE='true'
ENV SCHEDULE=''
ENV PASSPHRASE=''
ENV BACKUP_KEEP_DAYS=''

COPY src/run.sh run.sh
COPY src/env.sh env.sh
COPY src/backup.sh backup.sh
COPY src/restore.sh restore.sh

CMD ["sh", "run.sh"]