#!/bin/sh

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1"
fi

# Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

# Ensure we are using text output
export AWS_DEFAULT_OUTPUT=text

if [ -n "${DEST_DIR}" ]; then
  target=s3://${AWS_S3_BUCKET}/${DEST_DIR}
else
  target=s3://${AWS_S3_BUCKET}
fi


# The source folder
source="${SOURCE_DIR:-build}"

#  Sync using our dedicated profile and suppress verbose messages.
#   - Upload index first.
#   - Then the other top level files.
#   - Then the static files.

aws s3 sync ${source} ${target} \
              --metadata-directive REPLACE \
              --cache-control max-age=86400 \
              --exclude index.html --exclude 'static/*' \
              --no-progress \
              --delete \
              ${ENDPOINT_APPEND} $* \
&& aws s3 sync ${source}/static ${target}/static \
              --metadata-directive REPLACE \
              --cache-control max-age=31536000 \
              --no-progress \
              ${ENDPOINT_APPEND} $* \
&& aws s3 cp ${source}/index.html ${target} \
              --metadata-directive REPLACE \
              --cache-control max-age=5 \
              --no-progress \
              ${ENDPOINT_APPEND} $*

SUCCESS=$?

if [ $SUCCESS -eq 0 ]
then
  echo "Deploy successful."
else
  echo "Failed to perform deploy!"
  exit 1
fi
