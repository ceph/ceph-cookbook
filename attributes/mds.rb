include_attribute 'ceph'

default['ceph']['mds']['init_style'] = node['init_style']

case node['platform_family']
when 'debian'
  packages = ['ceph-mds']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['mds']['packages'] = packages
else
  default['ceph']['mds']['packages'] = []
end
