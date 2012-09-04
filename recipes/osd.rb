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
include_recipe "ceph::default"
include_recipe "ceph::conf"

package 'gdisk' do
  action :upgrade
end

mons = get_mon_nodes()
have_mons = !mons.empty?
mons = get_mon_nodes("ceph_bootstrap_osd_key")

if not have_mons then
  puts "No ceph-mon found."
else

  while mons.empty?
    sleep(1)
    mons = get_mon_nodes("ceph_bootstrap_osd_key")
  end # while mons.empty?

  directory "/var/lib/ceph/bootstrap-osd" do
    owner "root"
    group "root"
    mode "0755"
  end

  # TODO cluster name
  cluster = 'ceph'

  file "/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw" do
    owner "root"
    group "root"
    mode "0440"
    content mons[0]["ceph_bootstrap_osd_key"]
  end

  execute "format as keyring" do
    command <<-EOH
      set -e
      # TODO don't put the key in "ps" output, stdout
      read KEY <'/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
      ceph-authtool '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring' --create-keyring --name=client.bootstrap-osd --add-key="$KEY"
      rm -f '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
    EOH
  end

  if is_crowbar?
    ruby_block "select new disks for ceph osd" do
      block do
        do_trigger = false
        node["crowbar"]["disks"].each do |disk, data|

          already_prepared = false
          if not node["crowbar_wall"].nil? and not node["crowbar_wall"]["ceph"].nil? and not node["crowbar_wall"]["ceph"][disk].nil? and not node["crowbar_wall"]["ceph"][disk]["prepared"].nil?
            already_prepared = true unless node["crowbar_wall"]["ceph"][disk]["prepared"] == false
          end

          if node["crowbar"]["disks"][disk]["usage"] == "Storage" and not already_prepared
            puts "Disk: #{disk} should be used for ceph"

            system 'ceph-disk-prepare', \
              "/dev/#{disk}"
            raise 'ceph-disk-prepare failed' unless $?.exitstatus == 0

            do_trigger = true

            node["crowbar_wall"]["ceph"] = {} unless node["crowbar_wall"]["ceph"]
            node["crowbar_wall"]["ceph"][disk] = {} unless node["crowbar_wall"]["ceph"][disk]
            node["crowbar_wall"]["ceph"][disk]["prepared"] = true
            node.save
          end
        end

        if do_trigger
          system 'udevadm', \
            "trigger", \
            "--subsystem-match=block", \
            "--action=add"
          raise 'udevadm trigger failed' unless $?.exitstatus == 0
        end

      end
    end
  end
end
