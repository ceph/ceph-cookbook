include_attribute 'ceph'

default['ceph']['mon']['init_style'] = node['ceph']['init_style']

default['ceph']['mon']['secret_file'] = '/etc/chef/secrets/ceph_mon'

case node['platform_family']
when 'debian', 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['mon']['packages'] = packages
else
  default['ceph']['mon']['packages'] = []
end
