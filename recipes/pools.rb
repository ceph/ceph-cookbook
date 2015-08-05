# Author:: mick-m <mick-m@users.noreply.github.com>
# Cookbook Name:: ceph
# Recipe:: pools
#
# Copyright 2015, Workday
#
# This recipe creates user-defined Ceph pools defined in the Chef environment.
# Having this code in a separate recipe allows better control of when the pools
# are created.

if node['ceph']['user_pools']
  node['ceph']['user_pools'].each do |pool|
    # Create user-defined pools
    ceph_pool pool['name'] do
      pg_num pool['pg_num']
      create_options pool['create_options'] if pool['create_options']
    end
  end
end
