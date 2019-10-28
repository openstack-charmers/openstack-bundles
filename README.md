# OpenStack-Bundles

This repo contains development and stable bundles for deploying OpenStack with Juju and MaaS with [OpenStack Charms](https://docs.openstack.org/charm-guide/latest).

## Local customization

Bundles are configured with default values. These values may not apply in the
environment being deployed. It may be necessary to update these settings for a
successful deployment. In particular, set the following to the appropriate
local values:

  ceph-osd:
    comment: SET osd-devices to match your environment
    options:
      osd-devices: /dev/sdb /dev/vdb
 
  neutron-gateway:
    comment: SET data-port to match your environment
    options:
      data-port: br-ex:eno2
 

#### Bundle Issues
If there are specific issues with the bundle yaml files, or the READMEs shipped with those bundles, please raise a bug against the openstack-bundles project in Launchpad:
 * https://bugs.launchpad.net/openstack-bundles/+filebug

#### MAAS or Juju Issues
If there are deploy-time issues, or other system/tooling prep issues, please see:
 * https://docs.openstack.org/charm-deployment-guide/latest/
 * https://www.jujucharms.com
 * https://www.maas.io

#### OpenStack Charms
For Q & A, please interact with the community on IRC or on the mailing list. More info can be found in the charm-guide:
 * https://docs.openstack.org/charm-guide/latest/find-us.html

