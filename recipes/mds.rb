#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: mds
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

include_recipe 'ceph'
include_recipe 'ceph::mds_install'

cluster = 'ceph'

directory "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}" do
  owner 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

ceph_client 'mds' do
  caps('osd' => 'allow *', 'mon' => 'allow rwx')
  keyname "mds.#{node['hostname']}"
  filename "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/keyring"
end

file "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/done" do
  owner 'root'
  group 'root'
  mode 00644
end

service_type = node['ceph']['osd']['init_style']

case service_type
when 'upstart'
  filename = 'upstart'
else
  filename = 'sysvinit'
end
file "/var/lib/ceph/mds/#{cluster}-#{node['hostname']}/#{filename}" do
  owner 'root'
  group 'root'
  mode 00644
end

service 'ceph_mds' do
  case service_type
  when 'upstart'
    service_name 'ceph-mds-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    service_name 'ceph'
  end
  action [:enable, :start]
  supports :restart => true
end
