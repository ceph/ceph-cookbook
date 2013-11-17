actions :add
default_action :add

attribute :name, :kind_of => String, :name_attribute => true
attribute :caps, :kind_of => Hash, :default => {"mon"=>"allow r", "osd"=>"allow r"}

# what the key should be called in the ceph cluster
# defaults to client.#{name}.#{hostname}
attribute :keyname, :kind_of => String

# where the key should be saved
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.keyring
attribute :filename, :kind_of => String

attr_accessor :exists
