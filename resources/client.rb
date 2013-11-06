actions :add
default_action :add

attribute :name, :kind_of => String, :name_attribute => true
attribute :description, :name_attribute => true, :kind_of => String, :default => nil
attribute :caps, :default => {"mon"=>"allow r", "osd"=>"allow r"}

# what the key should be called in the ceph cluster
# defaults to client.#{name}.#{hostname}
attribute :keyname, :kind_of => String, :default => nil

# where the key should be saved
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.keyring
attribute :filename, :kind_of => String, :default => nil
