cookbook_file "/etc/init/ceph-osd.conf" do
  source "upstart-ceph-osd.conf"
  mode 0644
end

cookbook_file "/etc/init/ceph-hotplug.conf" do
  source "upstart-ceph-hotplug.conf"
  mode 0644
end

service "ceph-osd-all" do
  provider Chef::Provider::Service::Upstart
  action [:enable]
end
