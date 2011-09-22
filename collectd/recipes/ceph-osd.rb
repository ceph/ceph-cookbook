 
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: collectd
# Recipe:: ceph-osd 
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

packages = %w{
	collectd
	collectd-core
}

packages.each do |pkg|
	package pkg do
		action :upgrade
	end
end

service "collectd" do 
	service_name "collectd"
	supports :restart => true
end

directories = %w{
	/etc/collectd
	/var/lib/collectd
	/var/lib/collectd/rrd
}

directories.each do |dir|
	directory dir do
		action :create
		mode 0755
		owner "root"
		group "root"
	end
end

hostname = node[:hostname]

osds = %x[/usr/bin/cconf -c /etc/ceph/ceph.conf --list-sections osd --filter-key-value host=#{hostname}]

template "/etc/collectd/collectd.conf" do
	source "collectd-osd.conf.erb"
	owner "root"
	group "root"
	mode 0644
	variables(
		:osds => osds
	)
	notifies :restart, "service[collectd]"
end

service "collectd" do
	action[:enable,:start]
end
