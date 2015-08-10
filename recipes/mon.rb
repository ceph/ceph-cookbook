# This recipe creates a monitor cluster
#
# You should never change the mon default path or
# the keyring path.
# Don't change the cluster name either
# Default path for mon data: /var/lib/ceph/mon/$cluster-$id/
#   which will be /var/lib/ceph/mon/ceph-`hostname`/
#   This path is used by upstart. If changed, upstart won't
#   start the monitor
# The keyring files are created using the following pattern:
#  /etc/ceph/$cluster.client.$name.keyring
#  e.g. /etc/ceph/ceph.client.admin.keyring
#  The bootstrap-osd and bootstrap-mds keyring are a bit
#  different and are created in
#  /var/lib/ceph/bootstrap-{osd,mds}/ceph.keyring

node.default['ceph']['is_mon'] = true

include_recipe 'ceph'
include_recipe 'ceph::mon_install'

service_type = node['ceph']['mon']['init_style']

directory '/var/run/ceph' do
  owner 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

directory "/var/lib/ceph/mon/ceph-#{node['hostname']}" do
  owner 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

# TODO: cluster name
cluster = 'ceph'

keyring = "#{Chef::Config[:file_cache_path]}/#{cluster}-#{node['hostname']}.mon.keyring"

execute 'format mon-secret as keyring' do # ~FC009
  command lazy { "ceph-authtool '#{keyring}' --create-keyring --name=mon. --add-key='#{mon_secret}' --cap mon 'allow *'" }
  creates keyring
  only_if { mon_secret }
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'generate mon-secret as keyring' do # ~FC009
  command "ceph-authtool '#{keyring}' --create-keyring --name=mon. --gen-key --cap mon 'allow *'"
  creates keyring
  not_if { mon_secret }
  notifies :create, 'ruby_block[save mon_secret]', :immediately
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'add bootstrap-osd key to keyring' do
  command lazy { "ceph-authtool '#{keyring}' --name=client.bootstrap-osd --add-key='#{osd_secret}' --cap mon 'allow profile bootstrap-osd'  --cap osd 'allow profile bootstrap-osd'" }
  only_if { node['ceph']['encrypted_data_bags'] && osd_secret }
end

ruby_block 'save mon_secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool '#{keyring}' --print-key --name=mon.")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['monitor-secret'] = key
    node.save
  end
  action :nothing
end

execute 'ceph-mon mkfs' do
  command "ceph-mon --mkfs -i #{node['hostname']} --keyring '#{keyring}'"
end

ruby_block 'finalise' do
  block do
    ['done', service_type].each do |ack|
      ::File.open("/var/lib/ceph/mon/ceph-#{node['hostname']}/#{ack}", 'w').close
    end
  end
end

if service_type == 'upstart'
  service 'ceph-mon' do
    provider Chef::Provider::Service::Upstart
    action :enable
  end
  service 'ceph-mon-all' do
    provider Chef::Provider::Service::Upstart
    supports :status => true
    action [:enable, :start]
  end
end

service 'ceph_mon' do
  case service_type
  when 'upstart'
    service_name 'ceph-mon-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    service_name 'ceph'
  end
  supports :restart => true, :status => true
  action [:enable, :start]
end

mon_addresses.each do |addr|
  execute "peer #{addr}" do
    command "ceph --admin-daemon '/var/run/ceph/ceph-mon.#{node['hostname']}.asok' add_bootstrap_peer_hint #{addr}"
    ignore_failure true
  end
end

# The key is going to be automatically created, We store it when it is created
# If we're storing keys in encrypted data bags, then they've already been generated above
if use_cephx? && !node['ceph']['encrypted_data_bags']
  ruby_block 'get osd-bootstrap keyring' do
    block do
      run_out = ''
      while run_out.empty?
        run_out = Mixlib::ShellOut.new('ceph auth get-key client.bootstrap-osd').run_command.stdout.strip
        sleep 2
      end
      node.set['ceph']['bootstrap_osd_key'] = run_out
      node.save
    end
    not_if { node['ceph']['bootstrap_osd_key'] }
  end
end
