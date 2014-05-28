include_recipe 'ceph::_common_install'

node['ceph']['cephfs']['packages'].each do |pck|
  package pck
end
