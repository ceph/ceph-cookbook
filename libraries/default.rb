require 'ipaddr'
require 'json'

def is_crowbar?()
  return defined?(Chef::Recipe::Barclamp) != nil
end

def get_mon_nodes(extra_search=nil)
  if is_crowbar?
    mon_roles = search(:role, 'name:crowbar-* AND run_list:role\[ceph-mon\]')
    if not mon_roles.empty?
      search_string = mon_roles.map { |role_object| "roles:"+role_object.name }.join(' OR ')
      search_string = "(#{search_string}) AND ceph_config_environment:#{node['ceph']['config']['environment']}"
    end
  else
    search_string = "role:ceph-mon AND chef_environment:#{node.chef_environment}"
  end

  if not extra_search.nil?
    search_string = "(#{search_string}) AND (#{extra_search})"
  end
  mons = search(:node, search_string)
  return mons
end

# If public_network is specified
# we need to search for the monitor IP
# in the node environment.
# 1. We look if the network is IPv6 or IPv4
# 2. We look for a route matching the network
# 3. We grab the IP and return it with the port
def find_node_ip_in_network(network, nodeish=nil)
  nodeish = node unless nodeish
  net = IPAddr.new(network)
  nodeish["network"]["interfaces"].each do |iface|
    if iface[1]["routes"].nil?
      next
    end
    if net.ipv4?
      iface[1]["routes"].each_with_index do |route, index|
        if iface[1]["routes"][index]["destination"] == network
          return "#{iface[1]["routes"][index]["src"]}:6789"
        end
      end
    else
      # Here we are getting an IPv6. We assume that
      # the configuration is stateful.
      # For this configuration to not fail in a stateless
      # configuration, you should run:
      #  echo "0" > /proc/sys/net/ipv6/conf/*/use_tempaddr
      # on each server, this will disabe temporary addresses
      # See: http://en.wikipedia.org/wiki/IPv6_address#Temporary_addresses
      iface[1]["routes"].each_with_index do |route, index|
        if iface[1]["routes"][index]["destination"] == network
          iface[1]["addresses"].each do |k,v|
            if v["scope"] == "Global" and v["family"] == "inet6"
              return "[#{k}]:6789"
            end
          end
        end
      end
    end
  end
end

def get_mon_addresses()
  mon_ips = []

  if File.exists?("/var/run/ceph/ceph-mon.#{node['hostname']}.asok")
    mon_ips = get_quorum_members_ips()
  else
    mons = []
    # make sure if this node runs ceph-mon, it's always included even if
    # search is laggy; put it first in the hopes that clients will talk
    # primarily to local node
    if node['roles'].include? 'ceph-mon'
      mons << node
    end

    mons += get_mon_nodes()
    if is_crowbar?
      mon_ips = mons.map { |node| Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address }
    else
      if node['ceph']['config']['global'] && node['ceph']['config']['global']['public network']
        mon_ips = mons.map { |nodeish| find_node_ip_in_network(node['ceph']['config']['global']['public network'], nodeish) }
      else
        mon_ips = mons.map { |node| node['ipaddress'] + ":6789" }
      end
    end
  end
  return mon_ips.uniq
end

def get_quorum_members_ips()
  mon_ips = []
  mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
  raise 'getting quorum members failed' unless $?.exitstatus == 0

  mons = JSON.parse(mon_status)['monmap']['mons']
  mons.each do |k|
    mon_ips.push(k['addr'][0..-3])
  end
  return mon_ips
end

QUORUM_STATES = ['leader', 'peon']
def have_quorum?()
    # "ceph auth get-or-create-key" would hang if the monitor wasn't
    # in quorum yet, which is highly likely on the first run. This
    # helper lets us delay the key generation into the next
    # chef-client run, instead of hanging.
    #
    # Also, as the UNIX domain socket connection has no timeout logic
    # in the ceph tool, this exits immediately if the ceph-mon is not
    # running for any reason; trying to connect via TCP/IP would wait
    # for a relatively long timeout.
    mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
    raise 'getting monitor state failed' unless $?.exitstatus == 0
    state = JSON.parse(mon_status)['state']
    return QUORUM_STATES.include?(state)
end
