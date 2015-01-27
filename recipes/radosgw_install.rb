include_recipe 'ceph'

node['ceph']['radosgw']['packages'].each do |pck|
  package pck
end
