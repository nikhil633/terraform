#!/bin/bash

set -e

echo "Starting EC2 bootstrap..."

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

apt-get install -y \
    docker.io \
    curl \
    wget \
    unzip \
    git \
    jq

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

echo "Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

rm -rf /tmp/aws
rm -f /tmp/awscliv2.zip

echo "EC2 bootstrap completed successfully."