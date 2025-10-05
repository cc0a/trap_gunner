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
#!/usr/bin/env bash
set -euo pipefail

echo "Enabling SSH and configuring firewall on remote Pi..."

ssh "$PI_USER@$PI_HOST" <<'EOF'
set -euo pipefail

echo "🔧 Enabling SSH service..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "🔒 Installing and configuring UFW..."
if ! command -v ufw &>/dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y ufw
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'Allow SSH'
sudo ufw limit 22/tcp comment 'Rate-limit SSH'
sudo ufw --force enable

echo "🚫 Hardening SSH configuration..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload ssh

echo "✅ SSH and UFW setup complete!"
sudo ufw status verbose
EOF

echo "Deployment complete!"
echo "EC2 instance is reachable at $EC2_IP"
echo "Private key copied to Raspberry Pi at $REMOTE_KEY_PATH"
echo "SSH enabled and UFW configured to allow port 22"