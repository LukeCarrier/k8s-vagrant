NETWORK = IPAddr.new("192.168.120.0/24")

unless NUM_MASTERS == 1 || NUM_MASTERS >= 3
  raise "At least one master is required in all configurations; HA configurations require at least 3"
end

unless IPAddr.method_defined?(:netmask)
  module IPAddrNetmaskExtensions
    def netmask
      _to_string(@mask_addr)
    end
  end

  IPAddr.include(IPAddrNetmaskExtensions)
end

def provision_network(vm, network, offset)
  # + 2 to avoid the network and router addresses
  ip_addr = IPAddr.new(network.to_i + 2 + offset, Socket::AF_INET)
  vm.network "private_network", ip: ip_addr.to_s, netmask: network.netmask
end

def provision_common(vm)
  vm.provision :shell, name: "upgrade", path: "provision/upgrade.sh"
  vm.provision :shell, name: "swap", path: "provision/swap.sh"
  vm.provision :shell, name: "runtime-docker", path: "provision/runtime/docker.sh"
end

def provision_master(vm)
  vm.provision :shell, name: "kubeadm", path: "provision/bootstrap/kubeadm.sh"
end

def init_cluster(vm)
  vm.provision :shell, name: "kubeadm-init", path: "provision/bootstrap/kubeadm-init.sh"
end

def configure_profile(vm)
  vm.provision :shell, name: "kube-profile", path: "provision/bootstrap/kubeadm-profile.sh"
end

def provision_cluster(vm)
  vm.provision :shell, name: "apply-calico", path: "provision/pod-network/calico.sh"
end

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian10"

  config.vm.define("master0") do |master|
    master.vm.hostname = "master0"

    provision_network(master.vm, NETWORK, 0)
    provision_common(master.vm)
    provision_master(master.vm)
    init_cluster(master.vm)
    configure_profile(master.vm)
    provision_cluster(master.vm)
  end
end
