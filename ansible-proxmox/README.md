# ansible-proxmox

Configures the Proxmox VE hosts in the `proxmox` group of [inventory.yml](inventory.yml):

* Trusts the hosts' SSH keys and installs the Ansible SSH key.
* Updates packages and Proxmox, and disables the subscription notice.
* Installs the `truenas-proxmox` storage plugin (KSATechnologies apt repo) and restarts the Proxmox services.
* Installs the Prometheus PVE exporter and shell profile files from [templates](templates/), and sets up host users.

Each host also has a `node_ipv6` (ULA) in the inventory, kept in step with the Kubernetes inventories.

See the [repository README](../README.md) for prerequisites and secrets handling.

```bash
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yml -i inventory.yml --check --ask-vault-pass --ask-become-pass
ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```
