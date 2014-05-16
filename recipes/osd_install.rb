include_recipe 'ceph::_common_install'

node['ceph']['osd']['packages'].each do |pck|
  package pck
end
