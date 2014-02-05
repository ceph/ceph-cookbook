platform_family = node['platform_family']

case platform_family
when "rhel"
  if node['ceph']['el_add_epel'] == true
    include_recipe "yum-epel"
  end
end

branch = node['ceph']['branch']
if branch == "dev" && platform_family != "centos" && platform_family != "fedora"
  fail "Dev branch for #{platform_family} is not yet supported"
end

repo = node['ceph'][platform_family][branch]['repository']

yum_repository "ceph" do
  baseurl repo
  gpgkey node['ceph'][platform_family]['dev']['repository_key'] if branch == "dev"
end

if node['roles'].include?("ceph-tgt")
  yum_repository "ceph-extra" do
    baseurl node['ceph'][platform_family]['extras']['repository']
    gpgkey node['ceph'][platform_family]['extras']['repository_key']
  end
end
