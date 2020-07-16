# Kubernetes, on VMs.

This is a learning exercise and development playground.

## Setting it up

Tweak the numbers in the `Vagrantfile` as desired -- there are validations in there to ensure it looks reasonable. The example below will be based on a cluster with 3 masters and 8 nodes.

Bring up the first master to initialise the cluster:

```console
vagrant up master0
```
