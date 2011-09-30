# this recipe creates a single-node monitor cluster

include_recipe "ceph::mon"
include_recipe "ceph::conf"

execute 'create client.admin keyring' do
  creates '/etc/ceph/client.admin.keyring'
  command <<-EOH
set -e
cauthtool \
  --create-keyring \
  --gen-key \
  --name=client.admin \
  --set-uid=0 \
  --cap mon 'allow *' \
  --cap osd 'allow *' \
  --cap mds 'allow' \
  /etc/ceph/client.admin.keyring.tmp
mv /etc/ceph/client.admin.keyring.tmp /etc/ceph/client.admin.keyring
EOH
  creates '/etc/ceph/client.admin.keyring'
end

execute 'ceph-mon mkfs' do
  # TODO this is probably not an atomic test
  creates '/srv/mon.single/magic'
  command <<-EOH
set -e
install -d -m0700 /srv/mon.single.temp
cauthtool --create-keyring --gen-key --name=mon. /srv/mon.single.temp/keyring
cat /etc/ceph/client.admin.keyring >>/srv/mon.single.temp/keyring
monmaptool --create --clobber --add single #{node[:ipaddress]} /srv/mon.single.temp/monmap
osdmaptool --clobber --createsimple 1 /srv/mon.single.temp/osdmap
cmon --mkfs -i single --monmap=/srv/mon.single.temp/monmap --osdmap=/srv/mon.single.temp/osdmap --keyring=/srv/mon.single.temp/keyring
rm -rf /srv/mon.single.temp
touch /srv/mon.single/done
EOH
  creates '/srv/mon.single/done'
  notifies :start, "service[ceph-mon-all]", :immediately
end


# this keyring will be used by filestore nodes to add new osd
# instances
execute 'create client.bootstrap-osd keyring' do
  creates '/etc/ceph/client.bootstrap-osd.keyring'
  command <<-EOH
set -e
cauthtool \
  --create-keyring \
  --gen-key \
  --name=client.bootstrap-osd \
  /etc/ceph/client.bootstrap-osd.keyring.tmp
mv /etc/ceph/client.bootstrap-osd.keyring.tmp /etc/ceph/client.bootstrap-osd.keyring
EOH
  creates '/etc/ceph/client.bootstrap-osd.keyring'
end

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
    key = %x[cauthtool --name client.bootstrap-osd -p /etc/ceph/client.bootstrap-osd.keyring]
    raise 'cauthtool failed' unless $?.exitstatus == 0
    node.override['ceph_bootstrap_osd_key'] = key
    node.save
  end
end
