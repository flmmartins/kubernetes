#!/bin/bash
# In terraform you need to declare the backend type s3 and then you can switch around different environments
# by using different config files pointing to s3. However, this does not work when you have different backend types
# This script aims to terraform init using local files for local environment and s3 for prod environment

ENV=$1

case $ENV in
  prod)
    # Check required environment variables
    if [ -z "$AWS_ENDPOINT_URL_S3" ] || [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      echo "Error: Missing required environment variables for prod"
      echo "Please set the following:"
      echo "  - AWS_ENDPOINT_URL_S3"
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