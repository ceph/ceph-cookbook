release_or_autobuild = node["ceph_branch"].nil? ? "release" : "autobuild"

execute "add autobuild gpg key to apt" do
  command <<-EOH
wget -q -O- https://raw.github.com/ceph/ceph/master/keys/#{release_or_autobuild}.asc \
| sudo apt-key add -
  EOH
end

template '/etc/apt/sources.list.d/ceph.list' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'apt-sources-list.release.erb'
  variables(
    :codename => node[:lsb][:codename],
    :branch => node["ceph_branch"]
  )
end

execute 'apt-get update'
