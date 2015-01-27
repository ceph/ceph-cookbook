include_recipe 'ceph'

node['ceph']['mds']['packages'].each do |pck|
  package pck
end
