#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: osd
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

# this recipe allows bootstrapping new osds, with help from mon
# Sample environment:
# #knife node edit ceph1
# "osd_devices": [
#   {
#       "device": "/dev/sdc"
#   },
#   {
#       "device": "/dev/sdd",
#       "dmcrypt": true,
#       "journal": "/dev/sdd"
#   }
# ]

include_recipe 'ceph::default'
include_recipe 'ceph::conf'

package 'gdisk' do
  action :upgrade
end

package 'cryptsetup' do
  action :upgrade
  only_if { node['dmcrypt'] }
end

service_type = node['ceph']['osd']['init_style']
# Look for monitors with osd bootstrap keys.
# If we're storing keys in encrypted data bags, then we'll have to trust the roles
if use_cephx? && !node['ceph']['encrypted_data_bags']
  mons = get_mon_nodes('ceph_bootstrap_osd_key:*')
else
  mons = get_mon_nodes
end

return 'No ceph-mon found.' if mons.empty?

directory '/var/lib/ceph/bootstrap-osd' do
  owner 'root'
  group 'root'
  mode '0755'
end

# TODO: cluster name
cluster = 'ceph'

if node['ceph']['encrypted_data_bags']
  secret = Chef::EncryptedDataBagItem.load_secret(node['ceph']['osd']['secret_file'])
  osd_secret = Chef::EncryptedDataBagItem.load('ceph', 'osd', secret)['secret']
else
  osd_secret = mons[0]['ceph']['bootstrap_osd_key']
end

execute 'format as keyring' do
  command "ceph-authtool '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring' --create-keyring --name=client.bootstrap-osd --add-key='#{osd_secret}'"
  creates "/var/lib/ceph/bootstrap-osd/#{cluster}.keyring"
end

if crowbar?
  node['crowbar']['disks'].each do |disk, data|
    execute "ceph-disk-prepare #{disk}" do
      command "ceph-disk-prepare /dev/#{disk}"
      only_if { node['crowbar']['disks'][disk]['usage'] == 'Storage' }
      notifies :run, 'execute[udev trigger]', :immediately
    end

    ruby_block "set disk usage for #{disk}" do
      block do
        node.set['crowbar']['disks'][disk]['usage'] = 'ceph-osd'
        node.save
      end
    end
  end

  execute 'udev trigger' do
    command 'udevadm trigger --subsystem-match=block --action=add'
    action :nothing
  end
else
  # Calling ceph-disk-prepare is sufficient for deploying an OSD
  # After ceph-disk-prepare finishes, the new device will be caught
  # by udev which will run ceph-disk-activate on it (udev will map
  # the devices if dm-crypt is used).
  # IMPORTANT:
  #  - Always use the default path for OSD (i.e. /var/lib/ceph/
  # osd/$cluster-$id)
  #  - $cluster should always be ceph
  #  - The --dmcrypt option will be available starting w/ Cuttlefish
  if node['ceph']['osd_devices']
    devices = node['ceph']['osd_devices']

    devices = Hash[(0...devices.size).zip devices] unless devices.kind_of? Hash

    devices.each do |index, osd_device|
      unless osd_device['status'].nil?
        Log.info("osd: osd_device #{osd_device} has already been setup.")
        next
      end

      directory osd_device['device'] do # ~FC022
        owner 'root'
        group 'root'
        recursive true
        only_if { osd_device['type'] == 'directory' }
      end

      dmcrypt = osd_device['encrypted'] == true ? '--dmcrypt' : ''

      execute "ceph-disk-prepare on #{osd_device['device']}" do
        command "ceph-disk-prepare #{dmcrypt} #{osd_device['device']} #{osd_device['journal']}"
        action :run
        notifies :create, "ruby_block[save osd_device status #{index}]", :immediately
      end

      execute "ceph-disk-activate #{osd_device['device']}" do
        only_if { osd_device['type'] == 'directory' }
      end

      # we add this status to the node env
      # so that we can implement recreate
      # and/or delete functionalities in the
      # future.
      ruby_block "save osd_device status #{index}" do
        block do
          node.normal['ceph']['osd_devices'][index]['status'] = 'deployed'
          node.save
        end
        action :nothing
      end
    end
    service 'ceph_osd' do
      case service_type
      when 'upstart'
        service_name 'ceph-osd-all-starter'
        provider Chef::Provider::Service::Upstart
      else
        service_name 'ceph'
      end
      action [:enable, :start]
      supports :restart => true
    end
  else
    Log.info('node["ceph"]["osd_devices"] empty')
  end
end
