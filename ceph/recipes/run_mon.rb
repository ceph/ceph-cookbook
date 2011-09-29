template "/etc/init/ceph-mon.conf" do
  source "upstart-ceph-mon.conf.erb"
  mode 0644
end

template "/etc/init/ceph-mon-all.conf" do
  source "upstart-ceph-mon-all.conf.erb"
  mode 0644
  notifies :restart, "service[ceph-mon-all]", :delayed
end

service "ceph-mon-all" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end
