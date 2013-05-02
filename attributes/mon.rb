case node['platform']
when 'ubuntu'
  default["ceph"]["mon"]["init_style"] = "upstart"
else
  default["ceph"]["mon"]["init_style"] = "sysvinit"
end
