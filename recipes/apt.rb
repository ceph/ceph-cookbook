include_recipe "apt"

case node['ceph']['branch']
when "release"
  apt_repository "ceph-release" do
    repo_name "ceph"
    uri "http://ceph.newdream.net/debian/"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
  end
when "testing"
  apt_repository "ceph-testing" do
    repo_name "ceph"
    uri "http://ceph.newdream.net/debian-testing/"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
  end
when "autobuild"
  apt_repository "ceph-autobuild" do
    repo_name "ceph"
    uri "http://gitbuilder.ceph.com/ceph-deb-#{node['lsb']['codename']}-x86_64-basic/ref/autobuild"
    distribution node['lsb']['codename']
    components ["main"]
    key "https://raw.github.com/ceph/ceph/master/keys/autobuild.asc"
  end
end
