include_recipe 'ceph::_common_install'

node['ceph']['mds']['packages'].each do |pck|
  package pck
end
