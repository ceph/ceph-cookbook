# this recipe allows bootstrapping ceph clients

include_recipe "ceph::default"
include_recipe "ceph::conf"

mons = nil

if is_crowbar?
  # for now, just assume the first proposal is the right one if we aren't assigned one
  # TODO: this is a dirty, dirty hack because I don't want to work out the proper search
  ceph_proposal = node['nova']['ceph_instance']
  ceph_cluster_name = data_bag_item("crowbar", "bc-ceph-#{ceph_proposal}")["deployment"]["ceph"]["config"]["environment"]
  mons = get_mon_nodes(ceph_cluster_name, "ceph_bootstrap_client_key:*")
else
  mons = get_mon_nodes(node['ceph']['config']['environment'], "ceph_bootstrap_client_key:*")
end

if mons.empty? then
  Chef::Log.info("No ceph-mon having ceph_bootstrap_client_key found.")
else
  
  directory "/var/lib/ceph/bootstrap-client" do
    owner "root"
    group "root"
    mode "0755"
  end

  #TODO cluster name
  cluster = 'ceph'

  execute "format as keyring" do
    command <<-EOH
      set -e
      # TODO don't put the key in "ps" output, stdout
      ceph-authtool '/var/lib/ceph/bootstrap-client/#{cluster}.keyring' --create-keyring --name=client.bootstrap-client --add-key='#{mons[0]["ceph_bootstrap_client_key"]}'
      rm -f '/var/lib/ceph/bootstrap-client/#{cluster}.keyring.raw'
    EOH
    creates 'var/lib/ceph/bootstrap-client/#{cluster}.keyring'
  end
end
