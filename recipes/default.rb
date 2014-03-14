#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: default
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

packages = []

case node['platform_family']
when 'debian'
  packages = %w(
    ceph
    ceph-common
  )

  if node['ceph']['install_debug']
    packages_dbg = %w(
      ceph-dbg
      ceph-common-dbg
    )
    packages += packages_dbg
  end
when 'rhel', 'fedora'
  packages = %w(
    ceph
  )

  if node['ceph']['install_debug']
    packages_dbg = %w(
      ceph-debug
    )
    packages += packages_dbg
  end
end

packages.each do |pkg|
  package pkg do
    action :install
  end
end
