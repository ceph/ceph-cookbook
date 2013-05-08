default['ceph']['branch'] = "stable" # Can be stable, testing or dev.
# Major release version to install or gitbuilder branch
default['ceph']['version'] = "cuttlefish"
default['ceph']['el_add_epel'] = true
default['ceph']['debian']['stable']['repository'] = "http://ceph.com/debian-#{node['ceph']['version']}/"
default['ceph']['debian']['stable']['repository_key'] = "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc"
default['ceph']['debian']['testing']['repository'] = "http://www.ceph.com/debian-testing/"
default['ceph']['debian']['testing']['repository_key'] = "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc"
default['ceph']['debian']['dev']['repository'] = "http://gitbuilder.ceph.com/ceph-deb-#{node['lsb']['codename']}-x86_64-basic/ref/#{node['ceph']['version']}"
default['ceph']['debian']['dev']['repository_key'] = "https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc"
