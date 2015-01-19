def create_client
  # Client settings
  client_name = "cephfs.#{node['hostname']}"
  filename = "/etc/ceph/ceph.client.#{client_name}.secret"

  name = 'cephfs'
  ceph_client name do
    filename filename
    caps('mon' => 'allow r', 'osd' => 'allow rw', 'mds' => 'allow')
    as_keyring false
  end
end

def manage_mount(directory, subdir, use_fuse, action)
  # Client settings
  client_name = "cephfs.#{node['hostname']}"
  filename = "/etc/ceph/ceph.client.#{client_name}.secret"

  if use_fuse
    if subdir != '/'
      Chef::Application.fatal!("Can't use a subdir with fuse mounts yet")
    end
    mount "#{action} #{directory}" do
      mount_point directory
      fstype 'fuse.ceph'
      # needs two slashes to indicate a network mount to chef
      device "conf=//etc/ceph/ceph.conf,id=#{client_name},keyfile=#{filename}"
      options 'defaults,_netdev'
      dump 0
      pass 0
      action action
    end
  else
    mons = mon_addresses.sort.join(',') + ':' + subdir
    mount "#{action} #{directory}" do
      mount_point directory
      fstype 'ceph'
      device mons
      options "_netdev,name=#{client_name},secretfile=#{filename}"
      dump 0
      pass 0
      action action
    end
  end
end

def whyrun_supported?
  true
end

def create_mount(action)
  create_client
  directory @new_resource.directory
  manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, action)
end

action :mount do
  converge_by("Creating cephfs mount at #{@new_resource.directory}") do
    create_mount(:mount)
  end
end

action :remount do
  converge_by("Remounting cephfs mount at #{@new_resource.directory}") do
    create_mount(:remount)
  end
end

action :umount do
  converge_by("Unmounting cephfs mount at #{@new_resource.directory}") do
    manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, :umount)
  end
end

action :enable do
  converge_by("Enabling cephfs mount at #{@new_resource.directory}") do
    create_mount(:enable)
  end
end

action :disable do
  converge_by("Disabling cephfs mount at #{@new_resource.directory}") do
    manage_mount(@new_resource.directory, @new_resource.cephfs_subdir, @new_resource.use_fuse, :disable)
  end
end
