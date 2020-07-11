NUM_NODES = 1
NETWORK = IPAddr.new("192.168.120.0/24")

unless IPAddr.method_defined?(:netmask)
  module IPAddrNetmaskExtensions
    def netmask
      _to_string(@mask_addr)
    end
  end

  IPAddr.include(IPAddrNetmaskExtensions)
end

Vagrant.configure("2") do |config|
  (0..NUM_NODES - 1).each do |i|
    config.vm.define("node#{i}") do |node|
      node.vm.box = "generic/debian10"

      # + 2 to avoid the network and router addresses
      ip_addr = IPAddr.new(NETWORK.to_i + 2 + i, Socket::AF_INET)
      node.vm.network "private_network", ip: ip_addr.to_s, netmask: NETWORK.netmask

      node.vm.provision :shell, name: "upgrade", path: "provision/upgrade.sh"
    end
  end
end
