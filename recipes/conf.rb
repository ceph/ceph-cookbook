fail 'fsid must be set in config' if node['ceph']['config']['fsid'].nil?
fail 'mon_initial_members must be set in config' if node['ceph']['config']['mon_initial_members'].nil?

directory '/etc/ceph' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => mon_addresses,
    :is_rgw => node['ceph']['is_radosgw']
  )
  mode '0644'
end
