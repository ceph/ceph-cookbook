platform_family = node['platform_family']

case platform_family
when "rhel"
  if node['ceph']['el_add_epel'] == true
    # We need to do this since the EPEL
    # version might change
    version = node['platform_version'].to_i
    epel_package = %x[ curl -s http://dl.fedoraproject.org/pub/epel/fullfilelist | grep ^#{version}/#{node['kernel']['machine']}/epel-release ].chomp
    system "rpm -U http://dl.fedoraproject.org/pub/epel/#{epel_package}"
  end
end

branch = node['ceph']['branch']
if branch == "dev" and platform_family != "centos" and platform_family != "fedora"
  raise "Dev branch for #{platform_family} is not yet supported"
end

repo = node['ceph'][platform_family][branch]['repository']

if branch == "dev"
  # Instead of using the yum cookbook,
  # we do it this way. It avoids a dependency
  system "curl -s #{node['ceph'][platform_family]['dev']['repository_key']} > /etc/pki/rpm-gpg/RPM-GPG-KEY-CEPH"
  system "cat > /etc/yum.repos.d/ceph.repo << EOF\n" \
    "[ceph]\n" \
    "name=Ceph\n" \
    "baseurl=#{repo}\n" \
    "enabled=1\n" \
    "gpgcheck=1\n" \
    "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CEPH\n" \
    "EOF\n"
else
  #This is a stable or testing branch
  system "rpm -U #{node['ceph'][platform_family][branch]['repository']}"
end
