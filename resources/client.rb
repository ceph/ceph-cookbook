actions :add
default_action :add

attribute :name, :kind_of => String, :name_attribute => true
attribute :caps, :kind_of => Hash, :default => {"mon"=>"allow r", "osd"=>"allow r"}

# Whether to store the secret in a keyring file or a plain secret file
attribute :as_keyring, :kind_of => [TrueClass,FalseClass], :default => true

# what the key should be called in the ceph cluster
# defaults to client.#{name}.#{hostname}
attribute :keyname, :kind_of => String

# where the key should be saved
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.keyring if as_keyring
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.secret if not as_keyring
attribute :filename, :kind_of => String

attr_accessor :exists
