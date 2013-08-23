case node['platform']
when 'ubuntu'
  default["ceph"]["osd"]["init_style"] = "upstart"
else
  default["ceph"]["osd"]["init_style"] = "sysvinit"
end
default["ceph"]["osd"]["secret_file"] = "/etc/chef/secrets/ceph_osd"
