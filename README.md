# Chef cookbook [![Build Status](https://travis-ci.org/ceph/ceph-cookbook.svg?branch=master)](https://travis-ci.org/ceph/ceph-cookbook) [![Gitter chat](https://badges.gitter.im/ceph/ceph-cookbook.png)](https://gitter.im/ceph/ceph-cookbook)

## DESCRIPTION

Installs and configures Ceph, a distributed network storage and filesystem designed to provide excellent performance, reliability, and scalability.

The current version is focused towards deploying Monitors and OSD on Ubuntu.

For documentation on how to use this cookbook, refer to the [USAGE](#USAGE) section.

For help, use [Gitter chat](https://gitter.im/ceph/ceph-cookbook), [mailing-list](mailto:ceph-users-join@lists.ceph.com) or [issues](https://github.com/ceph/ceph-cookbook/issues)

## REQUIREMENTS

### Chef

>= 11.6.0

### Platform

Tested as working:

* Ubuntu Precise (12.04)

### Cookbooks

The ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode/cookbooks

* apt
* apache2


## ATTRIBUTES

### Ceph Rados Gateway

* node[:ceph][:radosgw][:api_fqdn]
* node[:ceph][:radosgw][:admin_email]
* node[:ceph][:radosgw][:rgw_addr]

## TEMPLATES

## USAGE

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel, or contact Inktank:

http://ceph.com/docs/master
http://ceph.com/resources/mailing-list-irc/
http://www.inktank.com/


### Ceph Monitor

Ceph monitor nodes should use the ceph-mon role.

Includes:

* ceph::default
* ceph::conf

### Ceph Metadata Server

Ceph metadata server nodes should use the ceph-mds role.

Includes:

* ceph::default

### Ceph OSD

Ceph OSD nodes should use the ceph-osd role

Includes:

* ceph::default
* ceph::conf

### Ceph Rados Gateway

Ceph Rados Gateway nodes should use the ceph-radosgw role

## Resources/Providers

### ceph\_client

The ceph\_client LWRP provides an easy way to construct a Ceph client key. These keys are needed by anything that needs to talk to the Ceph cluster, including RadosGW, CephFS, and RBD access.

#### Actions

- :add - creates a client key with the given parameters

#### Parameters

- :name - name attribute. The name of the client key to create. This is used to provide a default for the other parameters
- :caps - A hash of capabilities that should be granted to the client key. Defaults to `{ 'mon' => 'allow r', 'osd' => 'allow r' }`
- :as\_keyring - Whether the key should be saved in a keyring format or a simple secret key. Defaults to true, meaning it is saved as a keyring
- :keyname - The key name to register in Ceph. Defaults to `client.#{name}.#{hostname}`
- :filename - Where to save the key. Defaults to `/etc/ceph/ceph.client.#{name}.#{hostname}.keyring` if `as_keyring` and `/etc/ceph/ceph.client.#{name}.#{hostname}.secret` if not `as_keyring`
- :owner - Which owner should own the saved key file. Defaults to root
- :group - Which group should own the saved key file. Defaults to root
- :mode - What file mode should be applied. Defaults to '00640'

### ceph\_cephfs

The ceph\_cephfs LWRP provides an easy way to mount CephFS. It will automatically create a Ceph client key for the machine and mount CephFS to the specified location. If the kernel client is used, instead of the fuse client, a pre-existing subdirectory of CephFS can be mounted instead of the root.

#### Actions

- :mount - mounts CephFS
- :umount - unmounts CephFS
- :remount - remounts CephFS
- :enable - adds an fstab entry to mount CephFS
- :disable - removes an fstab entry to mount CephFS

#### Parameters

- :directory - name attribute. Where to mount CephFS in the local filesystem
- :use\_fuse - whether to use ceph-fuse or the kernel client to mount the filesystem. ceph-fuse is updated more often, but the kernel client allows for subdirectory mounting. Defaults to true
- :cephfs\_subdir - which CephFS subdirectory to mount. Defaults to '/'. An exception will be thrown if this option is set to anything other than '/' if use\_fuse is also true

## LICENSE AND AUTHORS

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
