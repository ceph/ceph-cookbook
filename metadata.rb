name 'ceph'
maintainer 'Kyle Bader'
maintainer_email 'kyle.bader@dreamhost.com'
license 'Apache 2.0'
description 'Installs/Configures the Ceph distributed filesystem'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.2.1'

depends	'apache2', '>= 1.1.12'
depends 'apt'
depends 'yum', '>= 3.0'
depends 'yum-epel'
