#!/usr/bin/env bash
set -euo pipefail

# Expand "~" and variables safely
PRIVATE_KEY_PATH=$(eval echo "${1:-}")
INVENTORY_FILE="${2:-}"

if [[ -z "$PRIVATE_KEY_PATH" ]]; then
  echo "ERROR: Private key PATH not provided!"
  exit 1
fi

if [[ ! -f "$PRIVATE_KEY_PATH" ]]; then
  echo "ERROR: Private key file does NOT exist at $PRIVATE_KEY_PATH"
  exit 1
fi

if [[ -z "$INVENTORY_FILE" ]]; then
  echo "ERROR: Inventory file path not provided!"
  exit 1
fi

# Fetch EC2 IP from Terraform
INSTANCE_IP=$(terraform output -raw instance_public_ip || true)

if [[ -z "$INSTANCE_IP" ]]; then
  echo "ERROR: Terraform output 'instance_public_ip' is empty or missing."
  exit 1
fi

mkdir -p "$(dirname "$INVENTORY_FILE")"

cat > "$INVENTORY_FILE" <<EOF
[aws]
$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$PRIVATE_KEY_PATH ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory created successfully:"
cat "$INVENTORY_FILE"
