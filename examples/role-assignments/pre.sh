#!/usr/bin/env bash
# This script is used to set up the environment for the default example.

# if the lib dir exists, cd to it then run terraform init and apply, then cd back
RND=$RANDOM

if [ -d "lib" ]; then
    cd lib
    terraform init
    terraform apply -auto-approve -var="prefix=$RND"
    cd ..
fi

echo "prefix = \"$RND\"" > terraform.tfvars
