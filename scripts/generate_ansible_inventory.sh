#!/usr/bin/env bash
set -euo pipefail

# Arguments
PRIVATE_KEY="${1:-}"
INVENTORY_FILE="${2:-}"

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "ERROR: Private key not provided!"
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
  echo "Run: terraform apply FIRST."
  exit 1
fi

mkdir -p "$(dirname "$INVENTORY_FILE")"

cat > "$INVENTORY_FILE" <<EOF
[aws]
$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$PRIVATE_KEY ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory created successfully:"
cat "$INVENTORY_FILE"

