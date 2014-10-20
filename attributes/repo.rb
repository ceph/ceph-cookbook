default['ceph']['branch'] = 'stable' # Can be stable, testing or dev.
# Major release version to install or gitbuilder branch
default['ceph']['version'] = 'firefly'
default['ceph']['el_add_epel'] = true
default['ceph']['repo_url'] = 'http://ceph.com'
default['ceph']['extras_repo_url'] = 'http://ceph.com/packages/ceph-extras'
default['ceph']['extras_repo'] = false

case node['platform_family']
when 'debian'
  # Debian/Ubuntu default repositories
  default['ceph']['debian']['stable']['repository'] = "#{node['ceph']['repo_url']}/debian-#{node['ceph']['version']}/"
  default['ceph']['debian']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['debian']['testing']['repository'] = "#{node['ceph']['repo_url']}/debian-testing/"
  default['ceph']['debian']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['debian']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-deb-#{node['lsb']['codename']}-x86_64-basic/ref/#{node['ceph']['version']}"
  default['ceph']['debian']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
  default['ceph']['debian']['extras']['repository'] = "#{node['ceph']['extras_repo_url']}/debian/"
  default['ceph']['debian']['extras']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
when 'rhel'
  # Redhat/CentOS default repositories
  default['ceph']['rhel']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/el6/x86_64/"
  default['ceph']['rhel']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['rhel']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/el6/x86_64/"
  default['ceph']['rhel']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['rhel']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-rpm-centos6-x86_64-basic/ref/#{node['ceph']['version']}/x86_64/"
  default['ceph']['rhel']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
  default['ceph']['rhel']['extras']['repository'] = "#{node['ceph']['extras_repo_url']}/rpm/rhel6/x86_64/"
  default['ceph']['rhel']['extras']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
when 'fedora'
  # Fedora default repositories
  default['ceph']['fedora']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/fc#{node['platform_version']}/x86_64/"
  default['ceph']['fedora']['stable']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['fedora']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/fc#{node['platform_version']}/x86_64/"
  default['ceph']['fedora']['testing']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
  default['ceph']['fedora']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-rpm-fc#{node['platform_version']}-x86_64-basic/ref/#{node['ceph']['version']}/RPMS/x86_64/"
  default['ceph']['fedora']['dev']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
  default['ceph']['fedora']['extras']['repository'] = "#{node['ceph']['extras_repo_url']}/rpm/fedora#{node['platform_version']}/x86_64/"
  default['ceph']['fedora']['extras']['repository_key'] = 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
when 'suse'
  # (Open)SuSE default repositories
  # Chef doesn't make a difference between suse and opensuse
  suse = Mixlib::ShellOut.new("head -n1 /etc/SuSE-release| awk '{print $1}'").run_command.stdout.chomp.downcase
  suse = 'sles' if suse == 'suse'
  suse_version = suse << Mixlib::ShellOut.new("grep VERSION /etc/SuSE-release | awk -F'= ' '{print $2}'").run_command.stdout.chomp

  default['ceph']['suse']['stable']['repository'] = "#{node['ceph']['repo_url']}/rpm-#{node['ceph']['version']}/#{suse_version}/x86_64/ceph-release-1-0.#{suse_version}.noarch.rpm"
  default['ceph']['suse']['testing']['repository'] = "#{node['ceph']['repo_url']}/rpm-testing/#{suse_version}/x86_64/ceph-release-1-0.#{suse_version}.noarch.rpm"
  default['ceph']['suse']['extras']['repository'] = "#{node['ceph']['extras_repo_url']}/rpm/#{suse_version}/x86_64/"
else
  fail "#{node['platform_family']} is not supported"
end
