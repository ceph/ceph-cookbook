use_inline_resources

def whyrun_supported?
  true
end

action :add do
  filename = @current_resource.filename
  keyname = @current_resource.keyname
  caps = @new_resource.caps.map { |k, v| "#{k} '#{v}'" }.join(' ')
  unless @current_resource.caps_match
    converge_by("Set caps for #{@new_resource}") do
      auth_set_key(keyname, caps)
    end
  end

  file filename do
    content file_content
    owner 'root'
    group 'root'
    mode '640'
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephClient.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.as_keyring(@new_resource.as_keyring)
  @current_resource.keyname(@new_resource.keyname || "client.#{current_resource.name}.#{node['hostname']}")
  @current_resource.caps(get_caps(@current_resource.keyname))
  default_filename = "/etc/ceph/ceph.client.#{@new_resource.name}.#{node['hostname']}.#{@new_resource.as_keyring ? "keyring" : "secret"}"
  @current_resource.filename(@new_resource.filename || default_filename)
  @current_resource.key = get_key(@current_resource.keyname)
  @current_resource.caps_match = true if @current_resource.caps == @new_resource.caps
end

def file_content
  @current_resource.as_keyring ? "[#{@current_resource.keyname}]\n\tkey = #{@current_resource.key}\n" : @current_resource.key
end

def get_key(keyname)
  cmd = "ceph auth print_key #{keyname}"
  Mixlib::ShellOut.new(cmd).run_command.stdout
end

def get_caps(keyname)
  caps = {}
  cmd = "ceph auth get #{keyname}"
  output = Mixlib::ShellOut.new(cmd).run_command.stdout
  output.scan(/caps\s*(\S+)\s*=\s*"([^"]*)"/) { |k, v| caps[k] = v }
  caps
end

def auth_set_key(keyname, caps)
  # find the monitor secret
  mon_secret = ''
  mons = get_mon_nodes
  if !mons.empty?
    mon_secret = mons[0]['ceph']['monitor-secret']
  elsif mons.empty? && node['ceph']['monitor-secret']
    mon_secret = node['ceph']['monitor-secret']
  else
    Chef::Log.warn('No monitor secret found')
  end
  # try to add the key
  cmd = "ceph auth get-or-create #{keyname} #{caps} --name mon. --key='#{mon_secret}'"
  get_or_create = Mixlib::ShellOut.new(cmd)
  get_or_create.run_command
  if get_or_create.stderr.scan(/EINVAL.*but cap.*does not match/)
    Chef::Log.info('Deleting old key with incorrect caps')
    # delete an old key if it exists and is wrong
    Mixlib::ShellOut.new("ceph auth del #{keyname}").run_command
    # try to create again
    get_or_create = Mixlib::ShellOut.new(cmd)
    get_or_create.run_command
  end
  get_or_create.error!
end
