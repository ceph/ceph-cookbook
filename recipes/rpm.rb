platform_family = node['platform_family']

case platform_family
when 'rhel'
  include_recipe 'yum-epel' if node['ceph']['el_add_epel']
end

branch = node['ceph']['branch']
if branch == 'dev' && platform_family != 'centos' && platform_family != 'fedora'
  fail "Dev branch for #{platform_family} is not yet supported"
end

yum_repository 'ceph' do
  baseurl node['ceph'][platform_family][branch]['repository']
  gpgkey node['ceph'][platform_family][branch]['repository_key']
end

yum_repository 'ceph-extra' do
  baseurl node['ceph'][platform_family]['extras']['repository']
  gpgkey node['ceph'][platform_family]['extras']['repository_key']
  only_if { node['ceph']['extras_repo'] }
end

package 'parted'    # needed by ceph-disk-prepare to run partprobe
package 'hdparm'    # used by ceph-disk activate
package 'xfsprogs'  # needed by ceph-disk-prepare to format as xfs
if node['platform_family'] == 'rhel' && node['platform_version'].to_f > 6
  package 'btrfs-progs' # needed to format as btrfs, in the future
end
if node['platform_family'] == 'rhel' && node['platform_version'].to_f < 7
  package 'python-argparse'
end
