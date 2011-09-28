template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => search(:node, "role:mon").map { |node| node["ipaddress"] + ":6789" }
  )
  mode '0644'
end
