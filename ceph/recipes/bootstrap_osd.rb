# this recipe allows bootstrapping new osds, with help from mon

include_recipe "ceph::osd"
include_recipe "ceph::conf"

if is_crowbar?
  mons = search(:node, "role:ceph-mon AND ceph_config_environment:#{node['ceph']['config']['environment']} AND ceph_bootstrap_osd_key:*")
else
  mons = search(:node, "role:ceph-mon AND chef_environment:#{node.chef_environment} AND ceph_bootstrap_osd_key:*")
end

if mons.length < 1 then
  puts "No ceph-mon found."
else

  directory "/var/lib/ceph/bootstrap-osd" do
    owner "root"
    group "root"
    mode "0755"
  end

  # TODO cluster name
  cluster = 'ceph'

  file "/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw" do
    owner "root"
    group "root"
    mode "0440"
    content mons[0]["ceph_bootstrap_osd_key"]
  end

  execute "format as keyring" do
    command <<-EOH
      set -e
      # TODO don't put the key in "ps" output, stdout
      read KEY <'/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
      ceph-authtool '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring' --create-keyring --name=client.bootstrap-osd --add-key="$KEY"
      rm -f '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
    EOH
  end
end
