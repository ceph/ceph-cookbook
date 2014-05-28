default['ceph']['cephfs_mount'] = '/ceph'

case node['platform_family']
when 'debian'
  packages = ['ceph-fs-common']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['cephfs']['packages'] = packages
else
  default['ceph']['cephfs']['packages'] = []
end
