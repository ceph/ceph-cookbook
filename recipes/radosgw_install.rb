include_recipe 'ceph::_common_install'

node['ceph']['radosgw']['packages'].each do |pck|
  package pck
end
