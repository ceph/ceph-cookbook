actions :mount, :umount, :remount, :enable, :disable
default_action :mount

attribute :directory, :kind_of => String, :name_attribute => true, :required => true
attribute :use_fuse, :kind_of => [TrueClass, FalseClass], :required => true, :default => true
attribute :cephfs_subdir, :kind_of => String, :default => '/'

def initialize(*args)
  super
  @action = :mount
  @run_context.include_recipe 'ceph'
  @run_context.include_recipe 'ceph::cephfs_install'
end
