
include_recipe 'ceph::repo' if node['ceph']['install_repo']
