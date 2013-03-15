include_recipe "apt"

case node['ceph']['branch']
when "stable"
  apt_repository "ceph-stable" do
    repo_name "ceph"
    uri "http://www.ceph.com/debian-#{node['ceph']['version']}/"
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
