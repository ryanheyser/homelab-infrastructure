# homelab-infrastructure

## Purpose
To bootstrap my homelab infrastructure to allow for better maintenance and rapid configuration changes. 

## Use

### Creating Secrets

#### Change Directory to the ansible secrets subdirectory
```bash
cd GITROOT/ansible/secrets
```

#### Creating an age key
```bash
age-keygen -o age.key
```

### Provision unencryped secret files
```bash
ls -1 *.sops.yaml.template | sed -e 's/\.template//' | xargs -I {} cp {}.template {}.unencrypted
```

#### Populate unencrypted secret files with values

##### docker.sops.yaml.unencrypted
- docker-user is your docker username
- docker-token is a docker token that requires public repo read-only privileges
- docker-email is your email attached to your docker username

##### github.sops.yaml.unencrypted
- GITHUB_TOKEN is a github token that requires admin privileges to repo

#### Encrypting unencrypted secrets
```bash
ls -1 *.sops.yaml.unencrypted | sed -e 's/\.unencrypted//' | xargs -I {} sh -c 'sops --encrypt --age $(cat age.key | grep public | awk -F":" "{print \$2}" | tr -d " ") "$1".unencrypted > "$1"' -- {}
``` 

### Running ansible playbook

#### Change Directory to the ansible subdirectory
```bash
cd GITROOT/ansible/
```

#### Install ansible requirements
```bash
ansible-galaxy install -r requirements.yml
```

#### Run ansible playbook
```bash

``` 