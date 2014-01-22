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

include_recipe "ceph::conf"

name = "cephfs"
client_name = "cephfs.#{node['hostname']}"
filename = "/etc/ceph/ceph.client.#{client_name}.secret"

ceph_client name do
  filename filename
  caps ({"mon" => "allow r", "osd" => "allow rw", "mds" => "allow"})
  as_keyring false
end

mons = get_mon_addresses()
mons = mons.join(",")
mons = mons + ":/"
if not mons.empty?
  directory node['ceph']['cephfs_mount']
  mount node['ceph']['cephfs_mount'] do
    fstype "ceph"
    device mons
    options "_netdev,name=#{client_name},secretfile=#{filename}"
    dump 0
    pass 0
    action [:mount, :enable]
  end
end
