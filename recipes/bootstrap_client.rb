# this recipe allows bootstrapping ceph clients

include_recipe "ceph::default"
include_recipe "ceph::conf"

mons = get_mon_nodes("ceph_bootstrap_client_key:*")

if mons.empty? then
  puts "No ceph-mon having ceph_bootstrap_client_key found."
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
