# Basic Ceph Cluster

*DEV/TEST ONLY*: This unstable, development example bundle deploys a Ceph (Quincy) cluster on Ubuntu 22.04 LTS. See also: [Stable Bundles](https://jujucharms.com/u/openstack-charmers).

## Requirements

This example bundle is designed to run on bare metal using Juju with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 3 physical servers prior to using this bundle.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary.

Servers should have:

 - A minimum of 8GB of physical RAM.
 - Enough CPU cores to support your capacity requirements.
 - Two disks (identified by /dev/sda and /dev/sdb); the first is used by MAAS for the OS install, the second for Ceph storage.

## Components
 - 3 Nodes for Ceph OSDs
 - 3 Ceph monitors in LXD containers on the OSD machines

All physical servers (not LXD containers) will also have NTP installed and configured to keep time in sync.

To horizontally scale Ceph:

    juju add-unit ceph-osd # Add one more unit
    juju add-unit -n50 ceph-osd # add 50 more units

## Ensuring it's working

To ensure your cluster is functioning correctly, run through the following commands.

Connect to a monitor shell:

    juju ssh ceph-mon/0

Check that the cluster is healthy:

    sudo ceph -s

[MAAS]: https://maas.io/
