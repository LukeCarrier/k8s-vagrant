# Kubernetes, on VMs.

This is a learning exercise and development playground.

## Setting it up

Tweak the numbers in the `Vagrantfile` as desired -- there are validations in there to ensure it looks reasonable. The example below will be based on a cluster with 3 masters and 8 nodes.

Bring up the first master to initialise the cluster:

```console
vagrant up master0
```

Make a note of the `--token`, `--discovery-token-ca-cert-hash` and `--certificate-key` values emitted during the `kubeadm-init` provisoner run, and complete these values in the `Vagrantfile`:

```ruby
KUBEADM_ENV = {
  CONTROL_PLANE_ENDPOINT: "192.168.120.2:6443",
  TOKEN: "voblvp.mpn1o6lsk4zw7v6m",
  DISCOVERY_TOKEN_CA_CERT_HASH: "sha256:ed7dbe6a3dd9fb011585c85493bcb7cbff41f0e8f759c253251d07181d26e5f9",
  CERTIFICATE_KEY: "06bda2ab2b734b2b94086f8fb0a3a728e3a3e1d437536926d5fcbc62ecbff638",
}
```

Now bring up the additional masters. Because our cluster has three masters, the others will be `master1` and `master2`:

```console
vagrant up master1
vagrant up master2
```

You're now free to bring up the nodes:

```console
vagrant up
```

With this complete, copy the `/etc/kubernetes/admin.conf` file to your host user's `~/.kube/config` file, and rename the context to something more descriptive. You're now able to run `kubectl` commands directly from your host.
