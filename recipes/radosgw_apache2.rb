#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw_apache2
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

# For EL, delete the current fastcgi configuration
# and set the correct owners for dirs and logs
# d_owner = d_group = 'root'
# if node['platform_family'] == 'rhel'
#   file "#{node['apache']['dir']}/conf.d/fastcgi.conf" do
#     action :delete
#     backup false
#   end
#   d_owner = d_group = 'apache'
# end

# %W(/var/run/ceph
#    /var/lib/ceph/radosgw/ceph-radosgw.#{node['hostname']}
#    /var/lib/apache2/
# ).each do |dir|
#   directory dir do
#     owner d_owner
#     group d_group
#     mode '0755'
#     recursive true
#     action :create
#   end
# end

include_recipe 'ceph'
include_recipe 'ceph::radosgw_apache2_repo'

node['ceph']['radosgw']['apache2']['packages'].each do |pck|
  package pck
end

include_recipe 'apache2'

apache_module 'fastcgi' do
  conf true
  notifies :restart, 'service[apache2]'
end

apache_module 'rewrite' do
  conf false
  notifies :restart, 'service[apache2]'
end

web_app 'rgw' do
  template 'rgw.conf.erb'
  server_name node['ceph']['radosgw']['api_fqdn']
  admin_email node['ceph']['radosgw']['admin_email']
  ceph_rgw_addr node['ceph']['radosgw']['rgw_addr']
end

directory node['ceph']['radosgw']['path'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template "#{node['ceph']['radosgw']['path']}/s3gw.fcgi" do
  source 's3gw.fcgi.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    :ceph_rgw_client => "client.radosgw.#{node['hostname']}"
  )
end

if node['platform_family'] == 'suse'
  bash 'Set MPM apache value' do
    code 'sed -i s/^[[:space:]]*APACHE_MPM=.*/APACHE_MPM=\"worker\"/ /etc/sysconfig/apache2'
    not_if 'grep -q "^[[:space:]]*APACHE_MPM=\"worker\"" /etc/sysconfig/apache2'
    notifies :restart, 'service[apache2]'
  end
end
