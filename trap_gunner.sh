#!/bin/bash
set -e

# ----------------------------
# User input
# ----------------------------
read -p "Enter local private key path: " LOCAL_KEY
read -p "Enter Raspberry Pi username: " PI_USER
read -p "Enter Raspberry Pi host (IP or hostname): " PI_HOST
read -p "Enter remote key path on Pi: " REMOTE_KEY_PATH

# ----------------------------
# Terraform deployment
# ----------------------------
terraform init
terraform apply -auto-approve

# Get the EC2 Public IP from Terraform output
EC2_IP=$(terraform output -raw ec2_public_ip)

# ----------------------------
# Prepare Pi for key transfer
# ----------------------------
echo "Creating ~/.ssh directory on Pi..."
ssh "$PI_USER@$PI_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# Copy private key to Raspberry Pi
echo "Copying private key to Pi..."
scp -i "$LOCAL_KEY" "$LOCAL_KEY" "$PI_USER@$PI_HOST:$REMOTE_KEY_PATH"

# Set proper permissions for the private key
ssh "$PI_USER@$PI_HOST" "chmod 600 $REMOTE_KEY_PATH"

# ----------------------------
# Enable SSH and configure UFW
# ----------------------------
echo "Enabling SSH service and allowing through UFW..."
ssh "$PI_USER@$PI_HOST" <<'EOF'
# Enable SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Ensure UFW is installed
if ! command -v ufw &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y ufw
fi

# Allow SSH through the firewall
sudo ufw allow 22/tcp
sudo ufw --force enable
EOF

echo "Deployment complete!"
echo "EC2 instance is reachable at $EC2_IP"
echo "Private key copied to Raspberry Pi at $REMOTE_KEY_PATH"
echo "SSH enabled and UFW configured to allow port 22"
