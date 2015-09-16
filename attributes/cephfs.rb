default['ceph']['cephfs_mount'] = '/ceph'
default['ceph']['cephfs_use_fuse'] = nil # whether the recipe's fuse mount uses cephfs-fuse instead of kernel client, defaults to heuristics

case node['platform_family']
when 'debian'
  packages = ['ceph-fs-common', 'ceph-fuse']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['cephfs']['packages'] = packages
when 'rhel', 'fedora', 'suse'
  default['ceph']['cephfs']['packages'] = ['ceph-fuse']
else
  default['ceph']['cephfs']['packages'] = []
end
