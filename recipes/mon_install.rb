include_recipe 'ceph::_common_install'

node['ceph']['mon']['packages'].each do |pck|
  package pck
end
