# OpenStack Charms: Dev/Test Cloud for Refstack Testing

This bundle is intended to aid in exercising refstack tests on a small metal footprint.  It does not yield a HA cloud and is not intended for production use.  It utilizes development and test-only config options to achieve density of applications.

## Requirements

This example bundle is designed to run on bare metal using Juju 2.x with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 3 physical servers prior to using this bundle (4 total machines including the Juju controller).

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

Servers should have:

 - A minimum of 16GB of physical RAM, 32GB or more is recommended due to density.
 - Enough CPU cores to support your capacity requirements, 8c or more is recommended due to the application container placement density.
 - Two disks (identified by /dev/sda and /dev/sdb); the first is used by MAAS for the Ubuntu and OpenStack install, the second for Ceph storage.
 - Two cabled network ports on eno1 and eno2 (see below).

Servers should have two physical network ports cabled; the first is used for general communication between services in the Cloud, the second is used for 'public' network traffic to and from instances (North/South traffic) running within the Cloud.

## Components

 - 1 Node for Neutron Gateway, Swift, Ceph, and other control/data plane in LXD containers.
 - 2 Nodes for Nova Compute, Ceph, and the remainder of the control/data plan in LXD containers.

## What next?

This guide is not intended to be a complete step-by-step or end-to-end document for the necessary post-deploy and test routines.

Configure the deployed cloud with network, tenant, keys, users, projects, and images.

Collect values necessary to construct the [Tempest][] config file which is required to run [Refstack][].

Exercise [Refstack][].

## Useful Cloud URLs

 - OpenStack Dashboard: http://openstack-dashboard_ip/horizon

[MAAS]: https://maas.io/
[Simplestreams]: https://launchpad.net/simplestreams
[OpenStack Neutron]: http://docs.openstack.org/admin-guide-cloud/content/ch_networking.html
[OpenStack Admin Guide]: http://docs.openstack.org/user-guide-admin/content
[Ubuntu Cloud Images]: http://cloud-images.ubuntu.com/xenial/current/
[Refstack]: https://docs.openstack.org/refstack/latest/
[Tempest]: https://docs.openstack.org/tempest/latest/
