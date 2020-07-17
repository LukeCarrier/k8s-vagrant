# Basic cluster configuration
NUM_MASTERS = 3
NETWORK = IPAddr.new("192.168.120.0/24")
GATEWAY = "192.168.120.1"
DEFAULT_NETWORK_INTERFACE = "ens6"
KUBEADM_ENV = {
  # Set these before initialising the cluster.
  CONTROL_PLANE_ENDPOINT: "192.168.120.2:6443",
  VERBOSITY: 5,

  # Set these after initialising the cluster.
  TOKEN: "",
  DISCOVERY_TOKEN_CA_CERT_HASH: "",
  CERTIFICATE_KEY: "",
}

# Constants
RESERVED_ADDRESSES = 2
CONTROL_PLANE_VIPS = 1

# Validate the cluster configuration as best we can
unless NUM_MASTERS % 2 == 1
  raise "HA configurations require an odd number of masters; all clusters need at least 1"
end

# Monkeypatch the IPAddr#netmask method into existence if we're running in an
# older Ruby version.
unless IPAddr.method_defined?(:netmask)
  module IPAddrNetmaskExtensions
    def netmask
      _to_string(@mask_addr)
    end
  end

  IPAddr.include(IPAddrNetmaskExtensions)
end

# Get the nth IP address within the subnet.
#
# @param [IPAddr] network
# @param [Integer] offset
# @return [String]
def cidr_host_addr(network, offset)
  # + 2 to avoid the network and router addresses
  IPAddr.new(network.to_i + RESERVED_ADDRESSES + offset, Socket::AF_INET).to_s
end

# Stand up common provisioners.
#
# Sets up provisioners for some common pre-Kubernetes installation tasks:
# * Upgrading the base operating system.
# * Disabling any swap partitions.
# * Installing the Docker runtime.
# * Installing kubeadm and related tools.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def provision_common(vm)
  vm.provision :shell, name: "upgrade", path: "provision/upgrade.sh"
  vm.provision :shell, name: "swap", path: "provision/swap.sh"
  vm.provision :shell, name: "runtime-docker", path: "provision/runtime/docker.sh"
  vm.provision :shell, name: "install-kubeadm", path: "provision/bootstrap/kubeadm.sh"
end

# Stand up apiserver proxy provisioner.
#
# Sets up a provisioner that installs static pod manifests for keepalived and
# haproxy, used to provide the virtual IP address for the control plane
# endpoint.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
# @param [IPAddr] network
# @param [Integer] master_num
# @param [String] master_ip_addr
def provision_apiserver_proxy(vm, network, master_num, master_ip_addr)
  is_primary = master_num == 0
  env = {
    # On the primary master we can install this configuration prior to
    # initialising the cluster with kubeadm init, but on the other master nodes
    # kubeadm join will fail a preflight check as it requires an empty manifests
    # directory. Since we install the static pod manifest after joining, we
    # need to restart the kubelet to get the pod to come up.
    RESTART_KUBELET: is_primary ? 0 : 1,

    LOCAL_PEER_ID: "master#{master_num}",
    LOCAL_PEER_IP_ADDR: master_ip_addr,
    APISERVER_VIP: cidr_host_addr(network, 0),
    START_AS_LEADER: is_primary ? "true" : "false",
    INTERFACE: DEFAULT_NETWORK_INTERFACE,
    APISERVER_BACKEND_PORT: 6443,
    APISERVER_FRONTEND_PORT: 6443,
  }

  remote_peers = (0..NUM_MASTERS - 1).map do |i|
       "  - id: master#{i}\n" \
    << "    address: #{cidr_host_addr(network, CONTROL_PLANE_VIPS + i)}\n" \
    << "    port: 10000\n"
  end
  remote_peers.delete_at(master_num)
  env[:REMOTE_PEERS] = remote_peers.join

  backends = (0..NUM_MASTERS - 1).map do |i|
       "  - port: #{env[:APISERVER_BACKEND_PORT]}\n" \
    << "    address: #{cidr_host_addr(network, CONTROL_PLANE_VIPS + i)}\n"
  end
  env[:BACKENDS] = backends.join

  vm.provision(
      :shell, name: "kube-vip", env: env,
      path: "provision/kube-vip.sh")
end

# Prepare network adapters.
#
# Adds a private network (the default network is unsuitable as some providers
# require use of DHCP) and configure it as our default gateway.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def provision_network(vm, ip_addr, gateway, netmask)
  vm.network(
      "private_network", ip: ip_addr, gateway: gateway, netmask: netmask)
end

# Stand up cluster initialisation provisioner.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def init_cluster(vm)
  vm.provision(
      :shell, name: "kubeadm-init", env: KUBEADM_ENV,
      path: "provision/bootstrap/kubeadm-init.sh")
end

# Stand up kubectl profile provisioner.
#
# Copy the Kubernetes admin configuration to the root user profile.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def configure_profile(vm)
  vm.provision(
      :shell, name: "kube-profile",
      path: "provision/bootstrap/kubeadm-profile.sh")
end

# Stand up a provisioner to perform post-initialisation cluster configuration steps.
#
# This is where we should configure RBAC and overlay networking before any pods
# are started or additional cluster nodes are joined.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def provision_cluster(vm)
  vm.provision(
      :shell, name: "apply-calico", path: "provision/pod-network/calico.sh")
end

# Stand up a provisioner to join a node to the cluster control plane.
#
# @param [VagrantPlugins::Kernel_V2::VMConfig] vm
def join_cluster_control_plane(vm)
  vm.provision(
      :shell, name: "kubeadm-join-control-plane", env: KUBEADM_ENV,
      path: "provision/bootstrap/kubeadm-join-control-plane.sh")
end

Vagrant.configure("2") do |config|
  # Use the vanilla Debian 10 (Buster) image.
  config.vm.box = "debian/buster64"

  # Bump up resource allocations to allow us to fly.
  config.vm.provider :libvirt do |domain|
    domain.cpus = 2
    domain.cputopology sockets: 1, cores: 2, threads: 1

    domain.memory = 2048
  end

  # Disable the default synced folder, for which this box requires an NFS server
  # on the host.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Define the first master in the cluster and initialise the cluster from it.
  config.vm.define("master0") do |master|
    master.vm.hostname = "master0"

    ip_addr = cidr_host_addr(NETWORK, CONTROL_PLANE_VIPS)
    provision_network(master.vm, ip_addr, GATEWAY, NETWORK.netmask)

    provision_common(master.vm)
    provision_apiserver_proxy(master.vm, NETWORK, 0, ip_addr)
    init_cluster(master.vm)
    configure_profile(master.vm)
    provision_cluster(master.vm)
  end

  # Join additional masters.
  (1..NUM_MASTERS - 1).each do |i|
    config.vm.define("master#{i}") do |master|
      master.vm.hostname = "master#{i}"

      ip_addr = cidr_host_addr(NETWORK, CONTROL_PLANE_VIPS + i)
      provision_network(master.vm, ip_addr, GATEWAY, NETWORK.netmask)

      provision_common(master.vm)
      join_cluster_control_plane(master.vm)
      provision_apiserver_proxy(master.vm, NETWORK, i, ip_addr)
      configure_profile(master.vm)
    end
  end
end
