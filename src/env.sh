#! /bin/sh

# Support reading secrets from files (docker secret support)
if [ -n "${MYSQL_PASSWORD_FILE:-}" ] && [ -f "$MYSQL_PASSWORD_FILE" ]; then
  export MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi

if [ -n "${S3_ACCESS_KEY_ID_FILE:-}" ] && [ -f "$S3_ACCESS_KEY_ID_FILE" ]; then
  export S3_ACCESS_KEY_ID=$(cat "$S3_ACCESS_KEY_ID_FILE")
fi

if [ -n "${S3_SECRET_ACCESS_KEY_FILE:-}" ] && [ -f "$S3_SECRET_ACCESS_KEY_FILE" ]; then
  export S3_SECRET_ACCESS_KEY=$(cat "$S3_SECRET_ACCESS_KEY_FILE")
fi

if [ -n "${PASSPHRASE_FILE:-}" ] && [ -f "$PASSPHRASE_FILE" ]; then
  export PASSPHRASE=$(cat "$PASSPHRASE_FILE")
fi

if [ -z "${S3_BUCKET:-}" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ -z "${MYSQL_HOST:-}" ]; then
  if [ -n "${MYSQL_PORT_3306_TCP_ADDR:-}" ]; then
    MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR
    MYSQL_PORT=$MYSQL_PORT_3306_TCP_PORT
  else
    echo "You need to set the MYSQL_HOST environment variable."
    exit 1
  fi
fi

if [ -z "${MYSQL_USER:-}" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ -z "${MYSQL_PASSWORD:-}" ]; then
  echo "You need to set the MYSQL_PASSWORD or MYSQL_PASSWORD_FILE environment variable."
  exit 1
fi

if [ -z "${S3_ENDPOINT:-}" ]; then
  aws_args=""
else
  aws_args="--endpoint-url $S3_ENDPOINT"
fi

if [ -n "${S3_ACCESS_KEY_ID:-}" ]; then
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
fi
if [ -n "${S3_SECRET_ACCESS_KEY:-}" ]; then
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
fi
export AWS_DEFAULT_REGION=${S3_REGION:-}
# MYSQL_PWD is the environment variable mysql client uses for password
export MYSQL_PWD=$MYSQL_PASSWORD