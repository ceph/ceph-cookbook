def whyrun_supported?
  true
end

action :add do
  filename = @current_resource.filename
  keyname = @current_resource.keyname
  caps = @new_resource.caps.map{|k,v| "#{k} '#{v}'"}.join(' ')
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource} already exists - nothing to do"
  else
    if @current_resource.caps != @new_resource.caps
      converge_by("create ceph auth key #{keyname}") do
        auth_set_key(keyname, caps) unless @current_resource.exists
      end
    end
    if @current_resource.as_keyring
      get_new_content = method(:get_new_key_file)
    else
      get_new_content = method(:get_new_key)
    end
    if get_saved_key_file(@current_resource.filename) != get_new_content.call(keyname)
      converge_by("save ceph auth key to #{filename}") do
        file filename do
          content lazy {get_new_content.call(keyname)}
          owner "root"
          group "root"
          mode "640"
        end
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephClient.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.as_keyring(@new_resource.as_keyring)
  @current_resource.keyname(@new_resource.keyname || "client.#{current_resource.name}.#{node['hostname']}")
  @current_resource.caps(get_caps(@current_resource.keyname))
  if @current_resource.as_keyring
    get_new_content = method(:get_new_key_file)
    @current_resource.filename(@new_resource.filename || "/etc/ceph/ceph.client.#{current_resource.name}.#{node['hostname']}.keyring")
  else
    get_new_content = method(:get_new_key)
    @current_resource.filename(@new_resource.filename || "/etc/ceph/ceph.client.#{current_resource.name}.#{node['hostname']}.secret")
  end
  if @current_resource.caps == @new_resource.caps and
     get_saved_key_file(@current_resource.filename) == get_new_content.call(@current_resource.keyname)
    @current_resource.exists = true
  end
end

def get_new_key(keyname)
  cmd = "ceph auth print_key #{keyname}"
  key = Mixlib::ShellOut.new(cmd).run_command.stdout
  key
end

def get_new_key_file(keyname)
  cmd = "ceph auth print_key #{keyname}"
  key = Mixlib::ShellOut.new(cmd).run_command.stdout
  "[#{keyname}]\n\tkey = #{key}\n"
end

def get_saved_key_file(filename)
  ::IO.read(filename) rescue ""
end

def get_caps(keyname)
  caps = {}
  cmd = "ceph auth get #{keyname}"
  output = Mixlib::ShellOut.new(cmd).run_command.stdout
  output.scan(/caps\s*(\S+)\s*=\s*"([^"]*)"/) {|k, v|
    caps[k] = v
  }
  caps
end

def auth_set_key(keyname, caps)
  # find the monitor secret
  mon_secret = ""
  mons = get_mon_nodes()
  if not mons.empty?
    mon_secret = mons[0]["ceph"]["monitor-secret"]
  elsif mons.empty? and node["ceph"]["monitor-secret"]
    mon_secret = node["ceph"]["monitor-secret"]
  else
    Chef::Log.warn("No monitor secret found")
  end
  # try to add the key
  set_cmd = "ceph auth get-or-create #{keyname} #{caps} --name mon. --key='#{mon_secret}'"
  set_cmd = Mixlib::ShellOut.new(set_cmd)
  cmd = set_cmd.run_command
  if cmd.stderr.scan(/EINVAL.*but cap.*does not match/)
    Chef::Log.info("Deleting old key with incorrect caps")
    # delete an old key if it exists and is wrong
    Mixlib::ShellOut.new("ceph auth del #{keyname}").run_command
    # try to create again
    set_cmd = "ceph auth get-or-create #{keyname} #{caps} --name mon. --key='#{mon_secret}'"
    set_cmd = Mixlib::ShellOut.new(set_cmd)
    cmd = set_cmd.run_command
  end
  cmd = set_cmd.error!
end
