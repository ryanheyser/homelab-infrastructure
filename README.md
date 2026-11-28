# homelab-infrastructure

Bootstraps the homelab: Proxmox hosts, Ubuntu node images, the RKE2 Kubernetes cluster, and the platform
services that hand the cluster over to Flux. Day-2 workloads live in the companion
[homelab-ops](https://github.com/ryanheyser/homelab-ops) repo, which Flux reconciles after bootstrap.

## Layout

| Directory | Purpose |
| --- | --- |
| [ubuntu-autoinstall](ubuntu-autoinstall/) | Builds an Ubuntu Server autoinstall ISO for cluster nodes. |
| [ansible-proxmox](ansible-proxmox/) | Prepares the Proxmox hosts (packages, TrueNAS storage plugin, SSH keys). |
| [ansible-kubernetes-cluster-creation](ansible-kubernetes-cluster-creation/) | Prepares the nodes and installs dual-stack RKE2 with Calico. |
| [ansible-kubernetes-cluster-provisioning](ansible-kubernetes-cluster-provisioning/) | Installs the bootstrap platform (MetalLB, Traefik, storage, Vault, External Secrets, cert-manager) and bootstraps Flux. |
| [ansible-kubernetes-uninstall](ansible-kubernetes-uninstall/) | Removes RKE2 from every node. Destructive. |

## Order of operations

1. Build and install the nodes from the autoinstall ISO. Each node's static IPv4 and IPv6 (ULA) addresses come
   from netplan on the host and must match `ansible_host` and `node_ipv6` in the inventories.
2. Run `ansible-kubernetes-cluster-creation` to install RKE2.
3. Run `ansible-kubernetes-cluster-provisioning` to install the bootstrap services and Flux.
4. Flux takes over from [homelab-ops](https://github.com/ryanheyser/homelab-ops).

## Prerequisites

* `ansible`, `sops`, `age`, `helm`, `kubectl` and the `flux` CLI on the machine that runs the playbooks.
* The age key at `~/.config/sops/age/keys.txt`. Every `*.enc` and `*.sops.yaml.enc` file is encrypted to it.
* The ansible-vault password. Inventories and `vars.yml` contain `!vault` strings (sudo passwords, tokens).

### Secrets

Secrets are committed only in encrypted form. Each workspace keeps them in its own `secrets/` directory, with a
`*.template` file showing the expected keys where one exists. To create or update one:

```bash
cp secrets/docker.sops.yaml.template secrets/docker.sops.yaml
# fill in the values
sops --encrypt --age "<age public key>" secrets/docker.sops.yaml > secrets/docker.sops.yaml.enc
rm secrets/docker.sops.yaml
```

Edit an existing encrypted file in place with `sops secrets/<file>.enc`. Never commit the decrypted copy.

## Running a playbook

From the workspace directory:

```bash
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yml -i inventory.yml --check --ask-vault-pass --ask-become-pass
ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```

Each workspace README lists what its playbook does and any extra setup.
