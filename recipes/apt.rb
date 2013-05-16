include_recipe "apt"

branch = node['ceph']['branch']

apt_repository "ceph-#{branch}" do
  repo_name "ceph"
  uri node['ceph']['debian'][branch]['repository']
  distribution node['lsb']['codename']
  components ['main']
  key node['ceph']['debian'][branch]['repository_key']
end

