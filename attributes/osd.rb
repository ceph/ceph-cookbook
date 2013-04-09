case node['platform']
when 'ubuntu'
  default["ceph"]["osd"]["init_style"] = "upstart"
else
  default["ceph"]["osd"]["init_style"] = "sysvinit"
end
