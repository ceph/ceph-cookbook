
include_recipe 'apt'

branch = node['ceph']['branch']

distribution_codename =
case node['lsb']['codename']
when 'jessie' then 'sid'
else node['lsb']['codename']
end

apt_repository 'ceph' do
  repo_name 'ceph'
  uri node['ceph']['debian'][branch]['repository']
  distribution distribution_codename
  components ['main']
  key node['ceph']['debian'][branch]['repository_key']
end

apt_repository 'ceph-extras' do
  repo_name 'ceph-extras'
  uri node['ceph']['debian']['extras']['repository']
  distribution distribution_codename
  components ['main']
  key node['ceph']['debian']['extras']['repository_key']
  only_if { node['ceph']['extras_repo'] }
end

if node['ceph']['is_radosgw'] \
 && node['ceph']['radosgw']['webserver_companion'] == 'apache2' \
 && node['ceph']['radosgw']['use_apache_fork'] == true
  case node['lsb']['codename']
  when 'precise', 'oneiric'
    apt_repository 'ceph-apache2' do
      repo_name 'ceph-apache2'
      uri "http://gitbuilder.ceph.com/apache2-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution distribution_codename
      components ['main']
      key 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
    end
    apt_repository 'ceph-modfastcgi' do
      repo_name 'ceph-modfastcgi'
      uri "http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution distribution_codename
      components ['main']
      key 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc'
    end
  else
    Log.info("Ceph's Apache and Apache FastCGI forks not available for this distribution")
  end
end
