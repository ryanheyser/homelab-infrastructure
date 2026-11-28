# ansible-kubernetes-uninstall

**Destructive.** Stops and removes RKE2 from every host in the `kubernetes` group: it runs `rke2-killall.sh` and
`rke2-uninstall.sh`, deletes the RKE2 and kubelet configuration, and cleans up related packages. All cluster state
on the nodes is lost.

Use it to rebuild the cluster from scratch, for example to change the pod or service CIDRs. Then run
[cluster creation](../ansible-kubernetes-cluster-creation/) and
[provisioning](../ansible-kubernetes-cluster-provisioning/) again. See the [repository README](../README.md) for
prerequisites.

Keep [inventory.yml](inventory.yml) in step with the cluster-creation inventory.

```bash
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yml -i inventory.yml --ask-vault-pass --ask-become-pass
```
