# this recipe allows bootstrapping new osds, with help from mon

include_recipe "ceph::osd"
include_recipe "ceph::conf"

package 'gdisk' do
  action :upgrade
end

mons = get_mon_nodes()

if mons.empty? then
  puts "No ceph-mon found."
else

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
