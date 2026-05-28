#!/usr/bin/env bash
# Run this from Kali AFTER the VM is installed and SSH is up.
# Usage: bash vm-setup/provision.sh
set -euo pipefail

VM_IP="192.168.1.225"
SSH_KEY="${HOME}/.ssh/omni_provision"
VM_SSH="ssh -o StrictHostKeyChecking=no -i $SSH_KEY omni@$VM_IP"
VM_SCP="scp -o StrictHostKeyChecking=no -i $SSH_KEY"
SUDO="sudo"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[1/4] Running base setup on VM..."
$VM_SSH "$SUDO bash -s" < "$PROJECT_DIR/vm-setup/setup.sh"

echo "[2/4] Copying project files to VM..."
# Create tarball excluding build artifacts and secrets backup
tar -czf /tmp/omni-store.tar.gz \
  -C "$PROJECT_DIR" \
  --exclude='.git' \
  --exclude='*.iso' \
  --exclude='vm-setup' \
  --exclude='__pycache__' \
  --exclude='node_modules' \
  --exclude='.next' \
  .

$VM_SCP /tmp/omni-store.tar.gz omni@192.168.1.225:/tmp/omni-store.tar.gz
$VM_SSH "$SUDO tar -xzf /tmp/omni-store.tar.gz -C /opt/omni-store/ && $SUDO rm /tmp/omni-store.tar.gz"
rm /tmp/omni-store.tar.gz

echo "[3/4] Applying production docker-compose overrides..."
$VM_SCP "$PROJECT_DIR/vm-setup/docker-compose.prod.yml" omni@192.168.1.225:/tmp/docker-compose.prod.yml
$VM_SSH "$SUDO mv /tmp/docker-compose.prod.yml /opt/omni-store/docker-compose.prod.yml"
$VM_SSH "$SUDO chown -R omni:omni /opt/omni-store"

# Patch the service to use prod override
$VM_SSH "$SUDO sed -i 's|docker compose up -d --build|docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build|' /etc/systemd/system/omni-store.service"
$VM_SSH "$SUDO sed -i 's|docker compose down|docker compose -f docker-compose.yml -f docker-compose.prod.yml down|' /etc/systemd/system/omni-store.service"
$VM_SSH "$SUDO systemctl daemon-reload"

echo "[4/4] Starting Omni Store..."
$VM_SSH "$SUDO systemctl start omni-store"
$VM_SSH "$SUDO systemctl status omni-store --no-pager"

echo ""
echo "[+] Provisioning complete!"
echo "    Web: http://192.168.1.225"
echo "    SSH: ssh omni@192.168.1.225  (management)"
echo "    SSH: ssh -i jonny_id_rsa jonny@192.168.1.225  (player path)"
