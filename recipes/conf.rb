mon_addresses = get_mon_addresses()

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => mon_addresses
  )
  mode '0644'
end
