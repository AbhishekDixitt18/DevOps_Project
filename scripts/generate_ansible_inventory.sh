#!/bin/bash
set -euo pipefail

KEY_PATH="$1"
INVENTORY_FILE="$2"
# Optional third arg: EC2 public IP (passed from Terraform during apply)
EC2_IP="${3-}"

if [ -z "$EC2_IP" ]; then
  echo "Fetching EC2 public IP from Terraform output..."
  # Try to read terraform output; suppress errors and fallback if missing
  EC2_IP=$(terraform output -raw instance_public_ip 2>/dev/null || true)
fi

if [ -z "$EC2_IP" ]; then
  echo "ERROR: Failed to determine EC2 public IP"
  exit 1
fi

cat > "$INVENTORY_FILE" <<EOF
[aws]
$EC2_IP ansible_user=ubuntu \
ansible_ssh_private_key_file=$KEY_PATH \
ansible_python_interpreter=/usr/bin/python3 \
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory created successfully:"
cat "$INVENTORY_FILE"
