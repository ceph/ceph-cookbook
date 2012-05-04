# this recipe allows bootstrapping new osds, with help from single_mon

include_recipe "ceph::osd"
include_recipe "ceph::conf"

if is_crowbar?
  mons = search(:node, "role:ceph-mon AND ceph_config_environment:#{node['ceph']['config']['environment']} AND ceph_bootstrap_osd_key:*")
else
  mons = search(:node, "role:ceph-mon AND chef_environment:#{node.chef_environment} AND ceph_bootstrap_osd_key:*")
end

raise "No single_mon found." if mons.length < 1
raise "Too many single_mons found." if mons.length > 1

directory "/var/lib/ceph/boostrap-osd" do
  owner "root"
  group "root"
  mode "0755"
end

# TODO cluster name
cluster = 'ceph'

file "/var/lib/ceph/boostrap-osd/#{cluster}.keyring.raw" do
  owner "root"
  group "root"
  mode "0440"
  content mons[0]["ceph_bootstrap_osd_key"]
end

execute "format as keyring" do
  command <<-EOH
    # TODO don't put the key in "ps" output
    read KEY <'/var/lib/ceph/boostrap-osd/#{cluster}.keyring.raw'
    ceph-authtool '/var/lib/ceph/boostrap-osd/#{cluster}.keyring' --name=client.bootstrap-osd --add-key="$KEY"
    rm -f '/var/lib/ceph/boostrap-osd/#{cluster}.keyring.raw'
EOH
end
