include_recipe 'ceph::_common_install'

# Tools needed by cookbook
node['ceph']['packages'].each do |pck|
  package pck
end

chef_gem 'netaddr'
