# this recipe creates a single-node monitor cluster

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
  notifies :start, "service[ceph-mon-all-starter]", :immediately
end


# TODO this will hang if you stopped ceph-mon manually; use some chef
# hook mechanism to ensure ceph is running? EXCEPT it might still hang
# if the mon is not in quorum! test that!
ruby_block "save osd bootstrap key in node attributes" do
  block do
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
