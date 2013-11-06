require "open3"

def get_key(keyname, caps, secret)
  ret = {}
  Open3.popen3("ceph auth get-or-create #{keyname} #{caps} --name mon. --key='#{secret}'") {|stdin, stdout, stderr, wait|
    ret['stdout'] = stdout.read
    ret['stderr'] = stderr.read
  }
  return ret
end

action :add do
  name = @new_resource.name
  desc = @new_resource.description || @new_resource.name
  keyname = @new_resource.keyname || "client.#{name}.#{node['hostname']}"
  filename = @new_resource.filename || "/etc/ceph/ceph.client.#{name}.#{node['hostname']}.keyring"
  caps = @new_resource.caps.select{|k,v|true}.map{|(k,v)| "#{k} '#{v}'"}.join(' ')

  orig = ::IO.read(filename) rescue ""

  # register the key
  status = get_key(keyname, caps, node["ceph"]["monitor-secret"])
  if status['stderr'].scan(/EINVAL.*but cap.*does not match/)
    # delete an old key if it exists and is wrong
    `ceph auth del #{keyname}`
    status = get_key(keyname, caps, node["ceph"]["monitor-secret"])
  end
  if status['stderr'] != ''
    raise "ceph auth: #{status['stderr']}"
  end

  # save the key
  keyring = status['stdout']
  if orig != keyring
    keyfile = ::File.new(filename, "w")
    keyfile.puts(keyring)
    keyfile.close
    @new_resource.updated_by_last_action(true)
  end
end
