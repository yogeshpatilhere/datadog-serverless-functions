#!/bin/bash

set -e

# Determine the S3 bucket to publish the template
if [ -z "$1" ]; then
    echo "Must specify a S3 bucket to publish the template"
    exit 1
else
    BUCKET=$1
fi

VERSION=$(grep -o 'Version: \d\.\d\.\d' template.yaml | cut -d' ' -f2)

# Validate the template
echo "Validating template.yaml"
aws cloudformation validate-template --template-body file://template.yaml

# Confirm to proceed
read -p "Publish version ${VERSION} to S3 bucket ${BUCKET} and create a Github release aws-dd-forwarder-${VERSION}. Continue (y/n)?" CONT
if [ "$CONT" != "y" ]; then
  echo "Abort";
fi

# Upload the template to the S3 bucket
echo "Uploading template.yaml to s3://${BUCKET}/templates/${VERSION}.yaml"
aws s3 cp template.yaml s3://${BUCKET}/templates/${VERSION}.yaml --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

# Create a github release
echo "Release aws-dd-forwarder-${VERSION} to github"
go get github.com/github/hub
zip -r function.zip .
hub release create -a function.zip -m "aws-dd-forwarder-${VERSION}" aws-dd-forwarder-${VERSION}

echo "Done!"
