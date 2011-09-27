execute "add autobuild gpg key to apt" do
  command <<-EOH
wget -q -O- https://raw.github.com/NewDreamNetwork/ceph/master/keys/release.asc \
| sudo apt-key add -
  EOH
end

template '/etc/apt/sources.list.d/ceph.list' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'apt-sources-list.release.erb'
  variables(
    :codename => node[:lsb][:codename]
  )
end

execute 'apt-get update'
