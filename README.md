Chef cookbook for deploying the Ceph storage system
===================================================

Note: "knife cookbook upload" needs this directory to be named "ceph".
Please clone the repository as

  git clone https://github.com/ceph/ceph-cookbooks.git ceph

(we cannot name this repository ceph.git, as that is the main project
itself)


DESCRIPTION
===========

Installs and configures Ceph, a distributed network storage and filesystem designed to provide excellent performance, reliability, and scalability.

The current version is focused towards deploying Monitors and OSD on Ubuntu.

For documentation on how to use this cookbook, refer to the [USAGE](#USAGE) section.

Work in progress:

* RadosGW
* MDS
* Other Distro (Debian, RHEL/CentOS, FC)

REQUIREMENTS
============

Platform
--------

Tested as working:

* Ubuntu Precise (12.04)

Cookbooks
---------

The ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode/cookbooks

* apt
* apache2


ATTRIBUTES
==========

Ceph Rados Gateway
------------------

* node[:ceph][:radosgw][:api_fqdn]
* node[:ceph][:radosgw][:admin_email]
* node[:ceph][:radosgw][:rgw_addr]

TEMPLATES
=========



USAGE
=====

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel, or contact Inktank:

http://ceph.com/docs/master
http://ceph.com/resources/mailing-list-irc/
http://www.inktank.com/


Ceph Monitor
------------

Ceph monitor nodes should use the ceph-mon role.

Includes:

* ceph::default
* ceph::conf

Ceph Metadata Server
--------------------

Ceph metadata server nodes should use the ceph-mds role.

Includes:

* ceph::default

Ceph OSD
--------

Ceph OSD nodes should use the ceph-osd role

Includes:

* ceph::default
* ceph::conf

Ceph Rados Gateway
------------------

Ceph Rados Gateway nodes should use the ceph-radosgw role


LICENSE AND AUTHORS
===================

* Author: Kyle Bader <kyle.bader@dreamhost.com>

* Copyright 2013, DreamHost Web Hosting and Inktank Storage Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
