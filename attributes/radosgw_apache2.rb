case node['platform_family']
when 'debian', 'suse'
  default['ceph']['radosgw']['apache2']['packages'] = ['libapache2-mod-fastcgi']
when 'rhel', 'fedora'
  default['ceph']['radosgw']['apache2']['packages'] = ['mod_fastcgi']
end
