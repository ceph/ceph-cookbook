include_recipe 'ceph'

node['ceph']['mon']['packages'].each do |pck|
  package pck
end
