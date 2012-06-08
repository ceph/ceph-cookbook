mon_addresses = get_mon_addresses()

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :fsid => node["ceph"]["config"]["fsid"],
    :mon_initial_members => node["ceph"]["config"]["mon_initial_members"],
    :mon_addresses => mon_addresses
  )
  mode '0644'
end
