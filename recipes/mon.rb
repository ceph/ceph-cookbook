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

require 'json'

include_recipe "ceph::default"
include_recipe "ceph::conf"

service "ceph-mon-all-starter" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end

# TODO cluster name
cluster = 'ceph'

execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
mkdir -p /var/run/ceph
# TODO chef creates doesn't seem to suppressing re-runs, do it manually
if [ -e '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done' ]; then
  echo 'ceph-mon mkfs already done, skipping'
  exit 0
fi
KR='/var/lib/ceph/tmp/#{cluster}-#{node['hostname']}.mon.keyring'
# TODO don't put the key in "ps" output, stdout
ceph-authtool "$KR" --create-keyring --name=mon. --add-key='#{node["ceph"]["monitor-secret"]}' --cap mon 'allow *'

ceph-mon --mkfs -i #{node['hostname']} --keyring "$KR"
rm -f -- "$KR"
touch /var/lib/ceph/mon/ceph-#{node['hostname']}/done
touch /var/lib/ceph/mon/ceph-#{node['hostname']}/upstart
EOH
  creates '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done'
  creates '/var/lib/ceph/mon/ceph-#{node["hostname"]}/upstart'
  notifies :start, "service[ceph-mon-all-starter]", :immediately
end

ruby_block "tell ceph-mon about its peers" do
  block do
    mon_addresses = get_mon_addresses()
    mon_addresses.each do |addr|
      system 'ceph', \
        '--admin-daemon', "/var/run/ceph/ceph-mon.#{node['hostname']}.asok", \
        'add_bootstrap_peer_hint', addr
      # ignore errors
    end
  end
end

# The key is going to be automatically
# created,
# We store it when it is created
ruby_block "get osd-bootstrap keyring" do
  block do
    osd_bootstrap_key = ""
    while osd_bootstrap_key.empty? do
       osd_bootstrap_key = %x[ ceph auth get-key client.bootstrap-osd ]
       sleep(1)
    end
    node.override['ceph_bootstrap_osd_key'] = osd_bootstrap_key
    node.save
  end
end

