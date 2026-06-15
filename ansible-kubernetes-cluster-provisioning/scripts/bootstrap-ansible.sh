#!/usr/bin/env bash
set -euo pipefail

HERE=$(dirname "$0")/..
cd "$HERE"

if ! command -v ansible-galaxy >/dev/null 2>&1; then
  echo "ansible-galaxy is not installed. Install Ansible first."
  exit 1
fi

echo "Installing Ansible collections from requirements.yml"
ansible-galaxy collection install -r requirements.yml

if command -v ansible-lint >/dev/null 2>&1; then
  echo "ansible-lint is installed: $(ansible-lint --version)"
else
  echo "ansible-lint not found. Install it with: pip install ansible-lint" >&2
fi

echo "Bootstrap complete. You can now run: ansible-lint --exclude=secrets/*.sops.yaml"
echo "Then do a dry-run: ansible-playbook -i inventory.yml playbook.yml --check --diff --skip-tags=secrets"
