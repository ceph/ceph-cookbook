default['ceph']['install_debug'] = false
default['ceph']['encrypted_data_bags'] = false

default['ceph']['install_repo'] = true

default['ceph']['user_pools'] = []

case node['platform']
when 'ubuntu'
  default['ceph']['init_style'] = 'upstart'
else
  default['ceph']['init_style'] = 'sysvinit'
end

case node['platform_family']
when 'debian'
  packages = ['ceph-common']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
when 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
else
  default['ceph']['packages'] = []
end
