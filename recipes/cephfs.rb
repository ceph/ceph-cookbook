#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: cephfs
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

requires_fuse =
  case node['platform']
  when 'debian'
    node['platform_version'].to_f < 7.0
  when 'ubuntu'
    node['platform_version'].to_f < 12.04
  when 'redhat'
    node['platform_version'].to_f < 7.0
  when 'fedora'
    node['platform_version'].to_f < 17.0
  else
    true
end

ceph_cephfs node['ceph']['cephfs_mount'] do
  use_fuse requires_fuse
  action [:mount, :enable]
end
