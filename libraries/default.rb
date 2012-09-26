def is_crowbar?()
  return defined?(Chef::Recipe::Barclamp) != nil
end

def get_mon_nodes(ceph_environment, extra_search=nil)
  if is_crowbar?
    mon_roles = search(:role, 'name:crowbar-* AND run_list:role\[ceph-mon\]')
    if not mon_roles.empty?
      search_string = mon_roles.map { |role_object| "role:"+role_object.name }.join(' OR ')
      search_string = "(#{search_string}) AND ceph_config_environment:#{ceph_environment}"
    end
  else
    search_string = "role:ceph-mon AND chef_environment:#{node.chef_environment}"
  end

  if not search_string.nil? and not extra_search.nil?
    search_string = "(#{search_string}) AND (#{extra_search})"
  end
  mons = []

  if not search_string.nil?
    mons = search(:node, search_string)
  end
  return mons
end

def get_mon_addresses()
  mons = []

  # make sure if this node runs ceph-mon, it's always included even if
  # search is laggy; put it first in the hopes that clients will talk
  # primarily to local node
  if node['roles'].include? 'ceph-mon'
    mons << node
  end

  if is_crowbar?
    #TODO: this sucks, and won't work for glance
    if not node['ceph'].nil? and not node['ceph']['config'].nil? and not node['ceph']['config']['environment'].nil?
      puts "is a ceph node; grabbing environment from ceph attributes"
      ceph_environment = node['ceph']['config']['environment']
    else
      puts "not a ceph node; grabbing environment by searching data bag for nova's Ceph proposal"
      ceph_proposal = node['nova']['ceph_instance']
      ceph_environment = data_bag_item("crowbar", "bc-ceph-#{ceph_proposal}")["deployment"]["ceph"]["config"]["environment"]
    end

    mons += get_mon_nodes(ceph_environment)
    mon_addresses = mons.map { |node| Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address }

  else
    mons += get_mon_nodes(node['ceph']['config']['environment'])
    mon_addresses = mons.map { |node| node["ipaddress"] }
  end

  mon_addresses = mon_addresses.map { |ip| ip + ":6789" }
  return mon_addresses.uniq
end

QUORUM_STATES = ['leader', 'peon']

def have_quorum?()
  # "ceph auth get-or-create-key" would hang if the monitor wasn't
  # in quorum yet, which is highly likely on the first run. This
  # helper lets us delay the key generation into the next
  # chef-client run, instead of hanging.
  #
  # Also, as the UNIX domain socket connection has no timeout logic
  # in the ceph tool, this exits immediately if the ceph-mon is not
  # running for any reason; trying to connect via TCP/IP would wait
  # for a relatively long timeout.
  mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
  raise 'getting monitor state failed' unless $?.exitstatus == 0
  state = JSON.parse(mon_status)['state']
  return QUORUM_STATES.include?(state)
end

def ceph_get_client_key(pool, service)
  #TODO cluster name
  cluster = 'ceph'
  hostname = %x[hostname]
  hostname.chomp!
  client_name = "client.#{hostname}.#{service}"
  key_path = "/var/lib/ceph/bootstrap-client/#{cluster}.#{client_name}.keyring"
  final_key_path = "/etc/ceph/#{cluster}.#{client_name}.keyring"
 
  client_key = %x[ceph --cluster #{cluster} --name client.bootstrap-client --keyring /var/lib/ceph/bootstrap-client/#{cluster}.keyring auth get-or-create-key #{client_name} osd "allow pool #{pool} rwx;" mon "allow rw"]
  
  file "#{key_path}.raw" do
    owner "root"
    group "root"
    mode "0440"
    content client_key
  end
  
  execute "format as keyring" do
    command <<-EOH
        set -e
        set -x
        # TODO don't put the key in "ps" output, stdout
        read KEY <"#{key_path}.raw"
        ceph-authtool #{key_path} --create-keyring --name=#{client_name} --add-key="$KEY"
        rm -f "#{key_path}.raw"
        mv #{key_path} #{final_key_path}
      EOH
  end
    
  return ["#{client_name}", final_key_path]
end
