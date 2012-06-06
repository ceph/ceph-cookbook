# this recipe creates a monitor cluster

require 'json'

include_recipe "ceph::mon"
include_recipe "ceph::conf"

execute 'create client.admin keyring' do
  command <<-EOH
set -e
ceph-authtool \
  --create-keyring \
  --gen-key \
  --name=client.admin \
  --set-uid=0 \
  --cap mon 'allow *' \
  --cap osd 'allow *' \
  --cap mds 'allow' \
  /etc/ceph/ceph.client.admin.keyring.tmp
mv /etc/ceph/ceph.client.admin.keyring.tmp /etc/ceph/ceph.client.admin.keyring
EOH
  creates '/etc/ceph/ceph.client.admin.keyring'
end

if is_crowbar?
  ipaddress = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address
else
  ipaddress = node['ipaddress']
end

service "ceph-mon-all-starter" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end

execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
install -d -m0700 /var/lib/ceph/tmp/mon-#{node['hostname']}.temp
ceph-authtool --create-keyring --gen-key --name=mon. /var/lib/ceph/tmp/mon-#{node['hostname']}.temp/keyring
cat /etc/ceph/ceph.client.admin.keyring >>/var/lib/ceph/tmp/mon-#{node['hostname']}.temp/keyring
monmaptool --create --clobber --add #{node['hostname']} #{ipaddress} /var/lib/ceph/tmp/mon-#{node['hostname']}.temp/monmap
osdmaptool --clobber --createsimple 1 /var/lib/ceph/tmp/mon-#{node['hostname']}.temp/osdmap
ceph-mon --mkfs -i #{node['hostname']} --monmap=/var/lib/ceph/tmp/mon-#{node['hostname']}.temp/monmap --osdmap=/var/lib/ceph/tmp/mon-#{node['hostname']}.temp/osdmap --keyring=/var/lib/ceph/tmp/mon-#{node['hostname']}.temp/keyring
rm -rf /var/lib/ceph/tmp/mon-#{node['hostname']}.temp
touch /var/lib/ceph/mon/ceph-#{node['hostname']}/done
EOH
  # TODO built-in done-ness flag for ceph-mon?
  creates '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done'
  notifies :start, "service[ceph-mon-all-starter]", :immediately
end

ruby_block "save osd bootstrap key in node attributes" do
  block do

    # "ceph auth get-or-create-key" would hang if the monitor wasn't
    # in quorum yet, which is highly likely on the first run. This
    # delays the bootstrap-key generation into the next chef-client
    # run, instead of hanging.

    # Also, as the UNIX domain socket connection has no timeout logic
    # in the ceph tool, this exits immediately if the ceph-mon is not
    # running for any reason; trying to connect via TCP/IP would wait
    # for a relatively long timeout.
    mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
    raise 'getting monitor state failed' unless $?.exitstatus == 0
    state = JSON.parse(mon_status)['state']
    QUORUM_STATES = ['leader', 'peon']
    if not QUORUM_STATES.include?(state) then
      puts 'ceph-mon is not in quorum, skipping bootstrap-osd key generation for this run'
    else
      key = %x[
        ceph auth get-or-create-key client.bootstrap-osd mon \
          "allow command osd create ...; \
          allow command osd crush set ...; \
          allow command auth add * osd allow\\ * mon allow\\ rwx; \
          allow command mon getmap"
      ]
      raise 'adding or getting bootstrap-osd key failed' unless $?.exitstatus == 0
      node.override['ceph_bootstrap_osd_key'] = key
      node.save
    end
  end
end
