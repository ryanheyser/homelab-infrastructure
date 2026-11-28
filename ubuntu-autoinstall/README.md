# ubuntu-autoinstall

Builds an Ubuntu Server autoinstall ISO for the cluster nodes. [createiso.sh](createiso.sh) downloads the live
server ISO, checks its SHA256, and adds the autoinstall configuration from [server/](server/).

## Setup

Decrypt the autoinstall user data (see the [repository README](../README.md) for the age key):

```bash
sops --decrypt server/user-data.enc > server/user-data
```

`server/user-data.template` shows the expected structure. Do not commit the decrypted `server/user-data`.

## Run

```bash
sudo ./createiso.sh
```

The script installs `xorriso` if it is missing. The Ubuntu release is set by `dlurl` and `shasumurl` in the script.
