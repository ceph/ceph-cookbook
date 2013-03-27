case node['platform_family']
when "rhel"
  version =  %x[ cat /etc/redhat-release | awk '{print $3}' | awk -F. '{print $1}' ].chomp
  release = "el" + version
  if node['ceph']['el_add_epel'] == true
    # We need to do this since the EPEL
    # version might change
    epel_package = %x[ curl -s http://dl.fedoraproject.org/pub/epel/fullfilelist | grep ^#{version}/#{node['kernel']['machine']}/epel-release ].chomp
    system "rpm -U http://dl.fedoraproject.org/pub/epel/#{epel_package}"
  end
when "fedora"
  version = %x[ cat /etc/fedora-release | awk '{print $3}' ].chomp
  release = "fc" + version
when "suse"
  suse = %x[ head -n1 /etc/SuSE-release| awk '{print $1}' ].chomp.downcase #can be suse or opensuse
  version = %x[ grep VERSION /etc/SuSE-release | awk -F'= ' '{print $2}' ].chomp
  release = suse + version
end

end_path = "/#{release}/x86_64/ceph-release-1-0.#{release}.noarch.rpm"
case node['ceph']['branch']
when "stable"
  path = "http://ceph.com/rpm-#{node['ceph']['version']}" + end_path
  system "rpm -U #{path}"
when "testing"
  path = "http://ceph.com/rpm-testing" + end_path
  system "rpm -U #{path}"
when "dev"
  if node['platform'] == "centos"
    baseurl="http://gitbuilder.ceph.com/ceph-rpm-centos#{version}-x86_64-basic/ref/#{node['ceph']['version']}/x86_64/"
  elsif node['platform'] == "fedora"
    baseurl="http://gitbuilder.ceph.com/ceph-rpm-#{release}-x86_64-basic/ref/#{node['ceph']['version']}/RPMS/x86_64/"
  else
    raise "repository not available for your distribution"
  end
  # Instead of using the yum cookbook,
  # we do it this way. It avoids a dependency
  system "curl -s 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc' > /etc/pki/rpm-gpg/RPM-GPG-KEY-CEPH"
  system "cat > /etc/yum.repos.d/ceph.repo << EOF\n" \
    "[ceph]\n" \
    "name=Ceph\n" \
    "baseurl=#{baseurl}\n" \
    "enabled=1\n" \
    "gpgcheck=1\n" \
    "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CEPH\n" \
    "EOF\n"
end
