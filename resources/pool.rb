#
# Cookbook Name:: ceph
# Resource:: pool
#
# Author:: Sergio de Carvalho <scarvalhojr@users.noreply.github.com>
#

actions :create, :delete
default_action :create

attribute :name, :kind_of => String, :name_attribute => true

# The total number of placement groups for the pool.
attribute :pg_num, :kind_of => Integer, :required => true

# Optional arguments for pool creation
attribute :create_options, :kind_of => String

# Forces a non-empty pool to be deleted.
attribute :force, :kind_of => [TrueClass, FalseClass], :default => false

attr_accessor :exists
