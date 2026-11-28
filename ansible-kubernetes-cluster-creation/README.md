# ansible-kubernetes-cluster-creation

Prepares the cluster nodes and installs RKE2 with the
[lablabs.rke2](https://github.com/lablabs/ansible-role-rke2) role. See the [repository README](../README.md) for
prerequisites, secrets handling and the overall order.

## What the playbook does

1. Checks every host is reachable, trusts its SSH host key and loads [vars.yml](vars.yml).
2. Prepares localhost and the nodes ([tasks/setup-local.yml](tasks/setup-local.yml),
   [tasks/setup.yml](tasks/setup.yml), [tasks/setup-kubernetes.yml](tasks/setup-kubernetes.yml)), installs sops
   and the Flux CLI.
3. Installs RKE2 ([tasks/rke2-p1.yml](tasks/rke2-p1.yml)): an HA control plane on the `controlnodes` group, agents
   on `workernodes`, with a kube-vip BGP VIP for the API server.
4. Finishes the install and configures the CNI ([tasks/rke2-p2.yml](tasks/rke2-p2.yml) to
   [tasks/rke2-p5.yml](tasks/rke2-p5.yml)): Multus plus Calico with BGP, nftables and WireGuard for IPv4 and IPv6.

The RKE2 version is pinned as `rke2_version` in `tasks/rke2-p1.yml`. After bootstrap, upgrades are done by the
system-upgrade-controller plans in homelab-ops.

## Networking

The cluster is dual-stack from creation; RKE2 cannot convert an existing IPv4-only cluster.

| Range | Use |
| --- | --- |
| `fd00:255::/56` | Pod IPv6 (Calico) |
| `fd00:254::/112` | Service IPv6 |
| `fd00:11::/64` | Node IPv6 (ULA on the home VLAN) |

IPv4 comes first in every list so Services keep IPv4 as their primary family.

## Inventory

[inventory.yml](inventory.yml) defines `controlnodes`, `workernodes` and the `kubernetes` parent group. Each host
sets:

* `ansible_host`: the node's IPv4 address.
* `node_ipv6`: the node's IPv6 ULA (for example `fd00:11::1:11`), passed to RKE2 as the second `node-ip`. The host
  must already have this address from netplan; the playbook does not configure it.
* `metallb_bgp_routerid`: the BGP router ID for that node.

Keep the same per-host values in the other workspaces' inventories.

## Secrets

| File | Contents |
| --- | --- |
| `secrets/docker.sops.yaml.enc` | Docker Hub credentials (`docker_user`, `docker_token`, `docker_email`) |
| `secrets/github.sops.yaml.enc` | `GITHUB_TOKEN` |
| `secrets/rke2.sops.yaml.enc` | `RKE2_SERVER_TOKEN`, the cluster join token |

`github_token` in [vars.yml](vars.yml) and the sudo passwords in the inventory are ansible-vault strings. To
replace one:

```bash
ansible-vault encrypt_string '<value>' --name 'github_token' --ask-vault-pass
```

## Run

```bash
ansible-galaxy install -r requirements.yml
ansible-lint --exclude=secrets/
ansible-playbook playbook.yml -i inventory.yml --check --ask-vault-pass --ask-become-pass
ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```

`playbook-k3s-nonworking.yml` is the old k3s playbook, kept for reference only. Do not run it.
