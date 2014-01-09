case node['platform']
when 'ubuntu'
  default["ceph"]["mds"]["init_style"] = "upstart"
else
  default["ceph"]["mds"]["init_style"] = "sysvinit"
end
