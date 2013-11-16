
action :add do
  auth_set_key(current_resource.keyname, current_resource.caps) unless current_resource.exists

  file filename do
    content lazy {auth_get_key(keyname)}
    owner "root"
    group "root"
    mode "640"
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephClient.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.keyname(@new_resource.keyname || "client.#{current_resource.name}.#{node['hostname']}")
  @current_resource.filename(@new_resource.filename || "/etc/ceph/ceph.client.#{current_resource.name}.#{node['hostname']}.keyring")
  if String === @new_resource.caps
    @current_resource.caps(@new_resource.caps)
  else
    @current_resource.caps(@new_resource.caps.map{|k,v| "#{k} '#{v}'"}.join(' '))
  end
  @current_resource.exists = true if @current_resource.caps == get_caps(@current_resource.keyname)
end

def get_key(keyname)
  cmd = "ceph auth print_key #{keyname}"
  Mixlib::ShellOut.new(cmd).run_command.stdout
end

def get_caps(keyname)
  cmd = "ceph auth print_caps #{keyname}"
  Mixlib::ShellOut.new(cmd).run_command.stdout
end

def auth_set_key(keyname, caps)
  ruby_block "set key: #{keyname}" do
    block do
      set_cmd = "ceph auth get-or-create #{keyname} --#{caps} --name mon. --key='#{node["ceph"]["monitor-secret"]}'"
      set_cmd = Mixlib::ShellOut.new(set_cmd)
      cmd = set_cmd.run_command
      if cmd.stderr.scan(/EINVAL.*but cap.*does not match/)
        # delete an old key if it exists and is wrong
        Mixlib::ShellOut.new("ceph auth del #{keyname}").run_command
        set_cmd.run_command.error!
      end
    end
  end
end
