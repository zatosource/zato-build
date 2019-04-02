#!/bin/bash


function usage(){
    echo "$0 ZATO_S3_ACCESS_KEY ZATO_S3_SECRET_KEY LOCAL_PATH ZATO_S3_BUCKET_NAME"
    echo ""
    echo "ZATO_S3_ACCESS_KEY: access key used to upload the packages"
    echo "ZATO_S3_SECRET_KEY: secret key used to upload the packages"
    echo "LOCAL_PATH: local path to sync"
    echo "ZATO_S3_BUCKET_NAME: S3 bucket name to sync to"
}

if [[ "$1" == "-h" || "$1" == "--help" ]] ; then
    usage
    exit 0
fi

if [[ -z "$1" ]] ; then
    echo Argument 1 must be the access key used to upload the packages.
    usage
    exit 1
fi

if [[ -z "$2" ]] ; then
    echo Argument 2 must be the secret key used to upload the packages.
    usage
    exit 1
fi

if [[ -z "$3" ]] ; then
    echo Argument 3 must be the local path to sync.
    usage
    exit 1
fi

if [[ -z "$4" ]] ; then
    echo Argument 4 must be the S3 bucket name to sync to.
    usage
    exit 1
fi

echo "Tests passed..Uploading packages"
s3cmd --access_key=$ZATO_S3_ACCESS_KEY --secret_key=$ZATO_S3_SECRET_KEY sync "${LOCAL_PATH}" "$ZATO_S3_BUCKET_NAME/"
echo "Packages uploaded"
