action :add do
  name = new_resource.name
  desc = new_resource.description || new_resource.name
  keyname = new_resource.keyname || "client.#{name}.#{node['hostname']}"
  filename = new_resource.filename || "/etc/ceph/ceph.client.#{name}.#{node['hostname']}.keyring"
  caps = new_resource.caps.select{|k,v|true}.map{|(k,v)| "#{k} '#{v}'"}.join(' ')
  ruby_block "create #{desc} client key" do
    block do
      keyring = %x[ ceph auth get-or-create #{keyname} #{caps} --name mon. --key='#{node["ceph"]["monitor-secret"]}' ]
      keyfile = ::File.new(filename, "w")
      keyfile.puts(keyring)
      keyfile.close
    end
  end
end
