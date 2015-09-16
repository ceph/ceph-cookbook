use_inline_resources

def whyrun_supported?
  true
end

action :add do
  filename = @current_resource.filename
  keyname = @current_resource.keyname
  as_keyring = @current_resource.as_keyring
  owner = @new_resource.owner
  group = @new_resource.group
  mode = @new_resource.mode

  if @current_resource.exists
    if @current_resource.keys_match && @current_resource.caps_match
      Chef::Log.info "Client #{@new_resource} already exists and matches "\
                     'specifications - nothing to do.'
    else
      converge_by("Recreating client #{@new_resource} as existing doesn't "\
                  'match specifications') do
        delete_entity(keyname)
        create_entity(keyname)
      end
    end
  else
    converge_by("Creating client #{@new_resource}") do
      create_entity(keyname)
    end
  end

  # Obtain the randomly generated key if one wasn't provided
  key = @new_resource.key || get_key(keyname)

  # update the key in the file
  file filename do # ~FC009
    content file_content(keyname, key, as_keyring)
    owner owner
    group group
    mode mode
    sensitive true if Chef::Resource::File.method_defined? :sensitive
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephClient.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.as_keyring(@new_resource.as_keyring)
  @current_resource.keyname(@new_resource.keyname || "client.#{@new_resource.name}.#{node['hostname']}")
  @current_resource.caps(get_caps(@current_resource.keyname))
  default_filename = "/etc/ceph/ceph.client.#{@new_resource.name}.#{node['hostname']}.#{@new_resource.as_keyring ? 'keyring' : 'secret'}"
  @current_resource.filename(@new_resource.filename || default_filename)
  @current_resource.key(get_key(@current_resource.keyname))
  @current_resource.caps_match = @current_resource.caps == @new_resource.caps
  @current_resource.keys_match = @new_resource.key.nil? || (@current_resource.key == @new_resource.key)
  @current_resource.exists = ! (@current_resource.key.nil? || @current_resource.key.empty?)
end

def file_content(keyname, key, as_keyring)
  if as_keyring
    "[#{keyname}]\n\tkey = #{key}\n"
  else
    key
  end
end

def get_key(keyname)
  cmd = "ceph auth print_key #{keyname} --name mon. --key='#{mon_secret}'"
  Mixlib::ShellOut.new(cmd).run_command.stdout
end

def get_caps(keyname)
  caps = {}
  cmd = "ceph auth get #{keyname} --name mon. --key='#{mon_secret}'"
  output = Mixlib::ShellOut.new(cmd).run_command.stdout
  output.scan(/caps\s*(\S+)\s*=\s*"([^"]*)"/) { |k, v| caps[k] = v }
  caps
end

def delete_entity(keyname)
  cmd_text = "ceph auth del #{keyname} --name mon. --key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} deleted"
end

def create_entity(keyname)
  tmp_keyring = "#{Chef::Config[:file_cache_path]}/.#{keyname}.keyring"

  if new_resource.key
    # store key provided in a temporary keyring file
    cmd_text = "ceph-authtool #{tmp_keyring} --create-keyring --name #{keyname} "\
               "--add-key '#{new_resource.key}'"
    cmd = Mixlib::ShellOut.new(cmd_text)
    cmd.run_command
    cmd.error!

    key_option = "-i #{tmp_keyring}"
  else
    key_option = ''
  end

  caps = new_resource.caps.map { |k, v| "#{k} '#{v}'" }.join(' ')

  cmd_text = "ceph auth #{key_option} add #{keyname} #{caps} --name mon. "\
             "--key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} created"

  # remove temporary keyring file
  file tmp_keyring do # ~FC009
    action :delete
    sensitive true if Chef::Resource::File.method_defined? :sensitive
  end
end
