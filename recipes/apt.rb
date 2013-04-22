include_recipe "apt"

case node['ceph']['branch']
when "stable"
  apt_repository "ceph-stable" do
    repo_name "ceph"
    uri "http://ceph.com/debian-#{node['ceph']['version']}/"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc"
  end
when "testing"
  apt_repository "ceph-testing" do
    repo_name "ceph"
    uri "http://www.ceph.com/debian-testing/"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc"
  end
when "dev"
  apt_repository "ceph-gitbuilder" do
    repo_name "ceph"
    uri "http://gitbuilder.ceph.com/ceph-deb-#{node['lsb']['codename']}-x86_64-basic/ref/#{node['ceph']['version']}"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc"
  end
end

if node['roles'].include?("ceph-radosgw") \
 && node["ceph"]["radosgw"]["webserver_companion"] == "apache2" \
 && node["ceph"]["radosgw"]["use_apache_fork"] == true
  case node['lsb']['codename']
  when "precise","oneiric"
    apt_repository "ceph-apache2" do
      repo_name "ceph-apache2"
      uri "http://gitbuilder.ceph.com/apache2-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution node['lsb']['codename']
      components ["main"]
      key "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc"
    end
    apt_repository "ceph-modfastcgi" do
      repo_name "ceph-modfastcgi"
      uri "http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-#{node['lsb']['codename']}-x86_64-basic/ref/master"
      distribution node['lsb']['codename']
      components ["main"]
      key "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc"
    end
  else
    Log.info("Ceph's Apache and Apache FastCGI forks not available for this distribution")
  end
end
