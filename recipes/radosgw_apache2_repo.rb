if node['ceph']['radosgw']['use_apache_fork'] == true
  if node.platform_family?('debian') &&
     %w(precise quantal raring saucy squeeze trusty wheezy).include?(node['lsb']['codename'])
    apt_repository 'ceph-apache2' do
      repo_name 'ceph-apache2'
      uri "http://gitbuilder.ceph.com/apache2-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution node['lsb']['codename']
      components ['main']
      key 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
    end
    apt_repository 'ceph-modfastcgi' do
      repo_name 'ceph-modfastcgi'
      uri "http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution node['lsb']['codename']
      components ['main']
      key 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
    end
  elsif (node.platform_family?('fedora') && [18, 19].include?(node['platform_version'].to_i)) ||
        (node.platform_family?('rhel') && [6].include?(node['platform_version'].to_i))
    platform_family = node['platform_family']
    platform_version = node['platform_version'].to_i
    yum_repository 'ceph-apache2' do
      baseurl "http://gitbuilder.ceph.com/apache2-rpm-#{node['platform']}#{platform_version}-x86_64-basic/ref/master"
      gpgkey node['ceph'][platform_family]['dev']['repository_key']
    end
    yum_repository 'ceph-modfastcgi' do
      baseurl "http://gitbuilder.ceph.com/mod_fastcgi-rpm-#{node['platform']}#{platform_version}-x86_64-basic/ref/master"
      gpgkey node['ceph'][platform_family]['dev']['repository_key']
    end
  else
    Log.info("Ceph's Apache and Apache FastCGI forks not available for this distribution")
  end
end
