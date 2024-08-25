# homelab-infrastructure-ubuntu-autoinstall
The purpose of this is to create an ubuntu-autoinstall image to deploy to kubernetes cluster hosts in my homelab

## Setup
1. Decrypt user-data, see [ansible readme](../ansible/README.md) for information on getting keys.
```bash
sops --decrypt server/user-data.enc >server/user-data
```

## Run
```bash
sudo ./createiso.sh
```
