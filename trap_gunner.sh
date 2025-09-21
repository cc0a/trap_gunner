#!/bin/bash
set -e

# Raspberry Pi info
PI_USER="pi"
PI_HOST="raspberrypi.local"
REMOTE_KEY_PATH="~/.ssh/my-key.pem"

# Run Terraform apply automatically
terraform init
terraform apply -auto-approve

# Get the EC2 Public IP from Terraform output
EC2_IP=$(terraform output -raw ec2_public_ip)

# Path to the Terraform-generated private kay
LOCAL_KEY="./my-key.pem"

# Ensure Pi ~/.ssh exists
ssh "SPI_USER@SPI_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# Copy private key to Raspberry Pi
scp -i "$LOCAL_KEY" "$PI_USER@$PI_HOST:$REMOTE_KEY_PATH" "$LOCAL_KEY"

# Set permissions for the private key
ssh "$PI_USER@$PI_HOST" "chmod 600 $REMOTE_KEY_PATH"


echo "Deployment complete!"
echo "EC2 instance is reachable at $EC2_IP"
echo "Private key copied to Raspberry Pi at $REMOTE_KEY_PATH"