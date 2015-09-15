name 'ceph'
maintainer 'Chris Jones'
maintainer_email 'cjones303@bloomberg.net, cjones@cloudm2.com'
license 'Apache 2.0'
description 'Installs/Configures the Ceph distributed filesystem'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.8.0'

depends	'apache2', '>= 1.1.12'
depends 'apt'
depends 'yum', '>= 3.0'
depends 'yum-epel'

source_url 'https://github.com/ceph/ceph-cookbook' if respond_to?(:source_url)
issues_url 'https://github.com/ceph/ceph-cookbook/issues' if respond_to?(:issues_url)
