# fail 'mon_initial_members must be set in config' if node['ceph']['config']['mon_initial_members'].nil?

unless node['ceph']['config']['fsid']
  Chef::Log.warn('We are genereting a new uuid for fsid')
  require 'securerandom'
  node.set['ceph']['config']['fsid'] = SecureRandom.uuid
  node.save
end

directory '/etc/ceph' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables lazy {
    {
      :mon_addresses => mon_addresses,
      :is_rgw => node['ceph']['is_radosgw']
    }
  }
  mode '0644'
end
