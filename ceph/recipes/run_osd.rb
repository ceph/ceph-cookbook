template "/etc/init/ceph-osd.conf" do
  source "upstart-ceph-osd.conf.erb"
  mode 0644
end

template "/etc/init/ceph-osd-all.conf" do
  source "upstart-ceph-osd-all.conf.erb"
  mode 0644
  notifies :restart, "service[ceph-osd-all]", :delayed
end

service "ceph-osd-all" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end
