# ansible-kubernetes-cluster-provisioning

Installs the services the cluster needs before Flux can manage it, then bootstraps Flux against
[homelab-ops](https://github.com/ryanheyser/homelab-ops). Run it after
[cluster creation](../ansible-kubernetes-cluster-creation/). See the [repository README](../README.md) for
prerequisites and secrets handling.

## What the playbook does

1. Preflight: checks for `~/.kube/config`, the age key at `~/.config/sops/age/keys.txt`, and the `sops`, `helm`,
   `kubectl` and `flux` binaries.
2. Installs Reflector and creates the Docker Hub registry credential Secrets.
3. Installs MetalLB and creates its **IPv4** bootstrap pools, BFD profile, BGP peer and advertisement
   ([tasks/metallb.yml](tasks/metallb.yml)), then the CoreDNS LoadBalancer. These objects are created only if they
   are missing: Flux (homelab-ops `network-system/metallb`) owns them afterwards and adds the IPv6 ranges, and a
   re-run never overwrites that.
4. Installs the Traefik CRDs, the NFS storage provisioners, and Vault.
5. Initializes and unseals Vault, then seeds its KV store from `secrets/vault-initial-secrets.sops.yaml.enc`
   ([tasks/vault-initialize.yml](tasks/vault-initialize.yml)).
6. Installs External Secrets, cert-manager, and bootstraps Flux on `ryanheyser/homelab-ops` (`main`).

Every Kubernetes task runs from localhost against `~/.kube/config`.

## Secrets

| File | Contents |
| --- | --- |
| `secrets/docker.sops.yaml.enc` | Docker Hub credentials (`docker_user`, `docker_token`, `docker_email`) |
| `secrets/github.sops.yaml.enc` | `GITHUB_TOKEN` for `flux bootstrap github` (needs admin on `homelab-ops`) |
| `secrets/vault-initial-secrets.sops.yaml.enc` | Values seeded into Vault for homelab-ops `ExternalSecret`s |
| `secrets/vault-operator-init-secret.key.enc` | Vault init output (unseal keys, root token) |

To add a value to Vault, add a key to `vault-initial-secrets` with `sops` and a matching task in
`tasks/vault-initialize.yml`. Optional values are guarded with `is defined` so a missing key skips the task, as
`network_system_cloudflare_ddns_cloudflare_api_token` (Vault `cloudflare-api-token` / `ddns-token`) does.

On a cluster that is already running, this playbook does not re-seed Vault: write the new value with `vault kv put`
yourself.

## Run

```bash
./scripts/bootstrap-ansible.sh
ansible-lint --exclude=secrets/
ansible-playbook playbook.yml -i inventory.yml --check --ask-vault-pass --ask-become-pass
ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```

`scripts/bootstrap-ansible.sh` installs the collections from [requirements.yml](requirements.yml). In CI, run
`ansible-galaxy collection install -r requirements.yml` instead.
