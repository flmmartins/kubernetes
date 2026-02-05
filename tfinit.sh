#!/bin/bash

ENV=$1

case $ENV in
  prod)
    # Check required environment variables
    if [ -z "$AWS_S3_ENDPOINT" ] || [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      echo "Error: Missing required environment variables for prod"
      echo "Please set the following:"
      echo "  - AWS_S3_ENDPOINT"
      echo "  - AWS_ACCESS_KEY_ID"
      echo "  - AWS_SECRET_ACCESS_KEY"
      exit 1
    fi

    ln -sf backend.prod backend.tf
    terraform init -reconfigure
    ;;
  local)
    ln -sf backend.local backend.tf
    terraform init -reconfigure
    ;;
  *)
    echo "Usage: ./tfinit.sh [prod|local]"
    exit 1
    ;;
esac