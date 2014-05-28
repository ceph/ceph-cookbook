include_attribute 'ceph'

default['ceph']['osd']['init_style'] = node['ceph']['init_style']

default['ceph']['osd']['secret_file'] = '/etc/chef/secrets/ceph_osd'

case node['platform_family']
when 'debian', 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['osd']['packages'] = packages
else
  default['ceph']['osd']['packages'] = []
end
