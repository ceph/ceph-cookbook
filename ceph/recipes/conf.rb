if is_crowbar?
  mon_addresses = search(:node, "role:ceph-mon AND ceph_config_environment:#{node['ceph']['config']['environment']}").map { |node| Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address + ":6789" }
else
  mon_addresses = search(:node, "role:ceph-mon AND chef_environment:#{node.chef_environment}").map { |node| node["ipaddress"] + ":6789" }
end

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => mon_addresses
  )
  mode '0644'
end
