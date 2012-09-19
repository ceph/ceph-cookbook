# this recipe creates a monitor cluster
raise "fsid must be set in config" if node["ceph"]["config"]['fsid'].nil?
raise "mon_initial_members must be set in config" if node["ceph"]["config"]['mon_initial_members'].nil?


require 'json'

include_recipe "ceph::default"
include_recipe "ceph::conf"

if is_crowbar?
  ipaddress = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address
else
  ipaddress = node['ipaddress']
end

service "ceph-mon-all-starter" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end

# TODO cluster name
cluster = 'ceph'

execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
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
EOH
  # TODO built-in done-ness flag for ceph-mon?
  creates '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done'
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

have_key = ::File.exists?('/etc/ceph/ceph.client.admin.keyring')

ruby_block "wait until quorum is formed" do
  block do
    while not have_key and not have_quorum? do # so, our first run and we have no quorum
      #sleep
      sleep(1)
    end
  end
end

ruby_block "create client.admin keyring" do
  block do
    if not have_key then
      if not have_quorum? then
        puts 'ceph-mon is not in quorum, skipping bootstrap-osd key generation for this run'
      else
        # TODO --set-uid=0
        key = %x[
        ceph \
          --name mon. \
          --keyring '/var/lib/ceph/mon/#{cluster}-#{node['hostname']}/keyring' \
          auth get-or-create-key client.admin \
          mon 'allow *' \
          osd 'allow *' \
          mds allow
        ]
        raise 'adding or getting admin key failed' unless $?.exitstatus == 0
        # TODO don't put the key in "ps" output, stdout
        system 'ceph-authtool', \
          '/etc/ceph/ceph.client.admin.keyring', \
          '--create-keyring', \
          '--name=client.admin', \
          "--add-key=#{key}"
        raise 'creating admin keyring failed' unless $?.exitstatus == 0
      end
    end
  end
end

ruby_block "save bootstrap keys in node attributes" do
  block do
    if node['ceph_bootstrap_osd_key'].nil? then
      raise "missing bootstrap_osd key but do have bootstrap_client key!" unless node['ceph_bootstrap_client_key'].nil?
      if not have_quorum? then
        puts 'ceph-mon is not in quorum, skipping bootstrap key generation for this run'
      else
        osd_key = %x[
          ceph \
            --name mon. \
            --keyring '/var/lib/ceph/mon/#{cluster}-#{node['hostname']}/keyring' \
            auth get-or-create-key client.bootstrap-osd mon \
            "allow command osd create ...; \
            allow command osd crush set ...; \
            allow command auth add * osd allow\\ * mon allow\\ rwx; \
            allow command mon getmap"
        ]
        raise 'adding or getting bootstrap-osd key failed' unless $?.exitstatus == 0
        node.override['ceph_bootstrap_osd_key'] = osd_key

        client_key = %x[
          ceph \
            --name mon. \
            --keyring '/var/lib/ceph/mon/#{cluster}-#{node['hostname']}/keyring' \
            auth get-or-create-key client.bootstrap-client mon \
            "allow command auth get-or-create-key * osd * mon *;"
        ]
        raise 'adding or getting bootstrap-client key failed' unless $?.exitstatus == 0
        node.override['ceph_bootstrap_client_key'] = client_key
        
        node.save
      end
    else #node['ceph_bootstrap_osd_key'] not nil
      raise "have ceph_bootstrap_osd_key but not bootstrap_client key!" unless !node['ceph_bootstrap_client_key'].nil?
    end
  end
end

