# this recipe creates a single-node monitor cluster

include_recipe "ceph::mon"
include_recipe "ceph::conf"

execute 'create client.admin keyring' do
  creates '/etc/ceph/ceph.client.admin.keyring'
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

service "ceph-mon-all" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end

execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
install -d -m0700 /var/lib/ceph/tmp/mon-single.temp
ceph-authtool --create-keyring --gen-key --name=mon. /var/lib/ceph/tmp/mon-single.temp/keyring
cat /etc/ceph/ceph.client.admin.keyring >>/var/lib/ceph/tmp/mon-single.temp/keyring
monmaptool --create --clobber --add single #{ipaddress} /var/lib/ceph/tmp/mon-single.temp/monmap
osdmaptool --clobber --createsimple 1 /var/lib/ceph/tmp/mon-single.temp/osdmap
ceph-mon --mkfs -i single --monmap=/var/lib/ceph/tmp/mon-single.temp/monmap --osdmap=/var/lib/ceph/tmp/mon-single.temp/osdmap --keyring=/var/lib/ceph/tmp/mon-single.temp/keyring
rm -rf /var/lib/ceph/tmp/mon-single.temp
touch /var/lib/ceph/mon/ceph-single/done
EOH
  # TODO built-in done-ness flag for ceph-mon?
  creates '/var/lib/ceph/mon/ceph-single/done'
  notifies :start, "service[ceph-mon-all]", :immediately
end


# this keyring will be used by filestore nodes to add new osd
# instances
execute 'create client.bootstrap-osd keyring' do
  creates '/etc/ceph/client.bootstrap-osd.keyring'
  command <<-EOH
set -e
ceph-authtool \
  --create-keyring \
  --gen-key \
  --name=client.bootstrap-osd \
  /etc/ceph/client.bootstrap-osd.keyring.tmp
mv /etc/ceph/client.bootstrap-osd.keyring.tmp /etc/ceph/client.bootstrap-osd.keyring
EOH
  creates '/etc/ceph/client.bootstrap-osd.keyring'
end

# TODO this will hang if you stopped ceph-mon manually; use some chef
# hook mechanism to ensure ceph is running?
execute 'authorize client.bootstrap-osd' do
  command <<-EOH
set -e
ceph auth add \
  -i /etc/ceph/client.bootstrap-osd.keyring \
  client.bootstrap-osd \
  mon \
    "allow command osd create; \
    allow command osd crush add ...; \
    allow command auth add * osd allow\\ * mon allow\\ rwx; \
    allow command mon getmap"
EOH
end

ruby_block "save osd bootstrap key in node attributes" do
  block do
    key = %x[ceph-authtool --name client.bootstrap-osd -p /etc/ceph/client.bootstrap-osd.keyring]
    raise 'ceph-authtool failed' unless $?.exitstatus == 0
    node.override['ceph_bootstrap_osd_key'] = key
    node.save
  end
end
