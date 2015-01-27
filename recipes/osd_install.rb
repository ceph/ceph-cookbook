include_recipe 'ceph'

node['ceph']['osd']['packages'].each do |pck|
  package pck
end
