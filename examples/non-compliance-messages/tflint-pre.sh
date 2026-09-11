#!/usr/bin/env bash
# This script is used to set up the environment for tflint of the non-compliance-messages example.
RANDOM_PREFIX=$RANDOM

if [ -d "lib" ]; then
    cd lib
    terraform init
    terraform apply -auto-approve -var="prefix=$RANDOM_PREFIX"
    cd ..
fi

echo "prefix = \"$RANDOM_PREFIX\"" > terraform.tfvars
