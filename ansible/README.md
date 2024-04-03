# homelab-infrastructure-ansible
The point of this document is to describe the steps needed to reproduce my current behavior.

## Setup

### Provision `inventory.yml`
1. Setup `inventory.yml` with the desired configuration

### Age/Sops

#### Pre-reqs
1. Install age on ansible localhost, see [install guide](https://github.com/FiloSottile/age#installation).
2. Create `secrets/age.key`:
```bash
age-keygen -o secrets/age.key
```
3. Retrieve age public key from `secrets/age.key`, will be used in later steps.
4. To decrypt files created in later steps, you will have to make a copy of this file:
```bash
mkdir -p $HOME/.config/sops/age
cp secrets/age.key ~/.config/sops/age/keys.txt
chmod 0400 ~/.config/sops/age/keys.txt
```

### Provision SOPS templates

#### docker.sops.yaml.template
1. Copy `secrets/docker.sops.yaml.template` to `secrets/docker.sops.yaml.unencrypted`
2. Provision `secrets/docker.sops.yaml.unencrypted` with docker hub credentials
3. Encrypt `secrets/docker.sops.yaml.unencrypted` to `secrets/docker.sops.yaml` by:
```bash
sops --encrypt --age '<age public key>' secrets/docker.sops.yaml.unencrypted >secrets/docker.sops.yaml
```

#### github.sops.yaml.template
1. Copy `secrets/github.sops.yaml.template` to `secrets/github.sops.yaml.unencrypted`
2. Provision `secrets/github.sops.yaml.unencrypted` with github credentials
3. Encrypt `secrets/github.sops.yaml.unencrypted` to `secrets/github.sops.yaml` by:
```bash
sops --encrypt --age '<age public key>' secrets/github.sops.yaml.unencrypted >secrets/github.sops.yaml
```

#### Optional
1. Delete the unencryped files `secrets/docker.sops.yaml.unencrypted` and `secrets/github.sops.yaml.unencrypted`
2. To decrypt:
```bash
sops --decrypt secrets/docker.sops.yaml
sops --decrypt secrets/github.sops.yaml
```

### Provision github_token
Replace ansible-vault encrypted string with the output of:
```bash
ansible-vault encrypt_string '<redacted>' --name 'github_token' --ask-vault-pass
```
This can be the same token created in the `github.sops.yaml.template` step above.

## Run

### Lint
```bash
ansible-lint --exclude=secrets/*.sops.yaml
```

### Check configuration
```bash
 ansible-playbook playbook.yml --check -i inventory.yml --ask-vault-pass --ask-become-pass
```

### Execute
```bash
 ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```
