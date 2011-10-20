template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => search(:node, "recipes:ceph\\:\\:single_mon AND chef_environment:#{node.chef_environment}").map { |node| node["ipaddress"] + ":6789" }
  )
  mode '0644'
end
