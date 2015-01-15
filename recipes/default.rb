include_recipe 'ceph::repo' if node['ceph']['install_repo']
include_recipe 'ceph::conf'

# Tools needed by cookbook
node['ceph']['packages'].each do |pck|
  package pck
end

chef_gem 'netaddr'
