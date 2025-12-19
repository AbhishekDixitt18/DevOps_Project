#!/bin/bash
set -e

KEY_PATH="$1"
INVENTORY_FILE="$2"
EC2_IP="$3"

if [ -z "$EC2_IP" ]; then
  echo "ERROR: EC2_IP not provided"
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
