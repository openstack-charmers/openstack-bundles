# LXD OpenStack Cloud

*DEV/TEST ONLY*: This unstable, development example bundle deploys an OpenStack Cloud (Queens release), configured to use [LXD][] (the lightweight container hypervisor), on Ubuntu 16.04, providing Dashboard, Compute, Network, Object Storage, Identity and Image services. See also: [Stable Bundles](https://jujucharms.com/u/openstack-charmers).

## Requirements

This example bundle is designed to run on bare metal using Juju with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 4 physical servers prior to using this bundle.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary.

Servers should have:

 - A minimum of 8GB of physical RAM.
 - Enough CPU cores to support your capacity requirements.
 - Two disks (identified by /dev/sda and /dev/sdb); the first is used by MAAS for the OS install, the second for LXD LVM storage.
 - Two cabled network ports on eno1 and eno2 (see below).

Servers should have two physical network ports cabled; the first is used for general communication between services in the Cloud, the second is used for 'public' network traffic to and from instances (North/South traffic) running within the Cloud.

## Components

 - 1 Node for Neutron Gateway and Ceph with RabbitMQ and MySQL under LXC containers.
 - 3 Nodes for Nova Compute and Ceph, with Keystone, Glance, Neutron, Nova Cloud Controller, Ceph RADOS Gateway, and Horizon under LXC containers.

All physical servers (not LXC containers) will also have NTP installed and configured to keep time in sync.

Neutron Gateway, Nova Compute and Ceph services are designed to be horizontally scalable.

To horizontally scale Nova Compute:

    juju add-unit nova-compute # Add one more unit
    juju add-unit -n5 nova-compute # Add 5 more units

To horizontally scale Neutron Gateway:

    juju add-unit neutron-gateway # Add one more unit
    juju add-unit -n2 neutron-gateway # Add 2 more unitsa

To horizontally scale Ceph:

    juju add-unit ceph-osd # Add one more unit
    juju add-unit -n50 ceph-osd # add 50 more units

**Note:** Ceph can be scaled alongside Nova Compute or Neutron Gateway by adding units using the --to option:

    juju add-unit --to <machine-id-of-compute-service> ceph-osd

**Note:** Other services in this bundle can be scaled in-conjunction with the hacluster charm to produce scalable, highly avaliable services - that will be covered in a different bundle.

## Ensuring it's working

To ensure your cloud is functioning correctly, download this bundle and then run through the following sections.

All commands are executed from within the expanded bundle.

### Install OpenStack client tools

In order to configure and use your cloud, you'll need to install the appropriate client tools:

    sudo apt install -y python-openstackclient \
        python-novaclient python-keystoneclient \
        python-glanceclient python-neutronclient

### Accessing the cloud

Check that you can access your cloud from the command line:

    source openrc
    openstack service list

You should get a full listing of all services registered in the cloud which should include identity, compute, image and network.

### Configuring an image

In order to run instances on your cloud, you'll need to upload a root disk archive to boot instances from:

    mkdir -p ~/images
    wget -O ~/images/xenial.tar.gz http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-root.tar.gz
    openstack image create xenial --file ~/images/xenial.tar.gz \
        --disk-format=raw \
	--container-format=bare \
	--public \
	--property architecture=x86_64

### Configure networking

For the purposes of a quick test, we'll setup an 'external' network and shared router ('provider-router') which will be used by all tenants for public access to instances:

    ./neutron-ext-net-ksv3 --network-type flat \
        -g <gateway-ip> -c <network-cidr> \
        -f <pool-start>:<pool-end> ext_net

for example (for a private cloud):

    ./neutron-ext-net-ksv3 --network-type flat \
        -g 10.245.168.1 -c 10.245.168.0/21 \
	-f 10.245.172.0:10.245.172.254 ext_net

You'll need to adapt the parameters for the network configuration that eno2 on all the servers is connected to; in a public cloud deployment these ports would be connected to a publicable addressable part of the Internet.

We'll also need an 'internal' network for the admin user which instances are actually connected to:

    ./neutron-tenant-net-ksv3 -p admin -r provider-router \
        [-N <dns-server>] internal 10.5.5.0/24

Neutron provides a wide range of configuration options; see the [OpenStack Neutron][] documentation for more details.

### Booting an instance

First generate a SSH keypair so that you can access your instances once you've booted them:

    mkdir -p ~/.ssh
    touch ~/.ssh/id_rsa_cloud
    chmod 600 ~/.ssh/id_rsa_cloud
    openstack keypair create testkey > ~/.ssh/id_rsa_cloud

**Note:** you can also upload an existing public key to the cloud rather than generating a new one:

    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

Then add a flavor for the instance to be created from:

    openstack flavor create  --id 1 --ram 2048  --disk 20 --vcpus 1 m1.small

You can now boot an instance on your cloud:

    openstack server create --flavor m1.small \
       --image xenial --key-name testkey \
       --nic net-id=$(openstack network list -c Name -c ID -f value | grep internal | awk '{print $1}') \
       xenial-test

### Accessing your instance

In order to access the instance you just booted on the cloud, you'll need to assign a floating IP address to the instance:

    openstack floating ip create ext_net
    openstack server add floating ip xenial-test <new-floating-ip>

and then allow access via SSH (and ping) - you only need to do these steps once:

    openstack security group list

For each security group in the list, identify the UUID and run:

    openstack security group rule create --protocol icmp <uuid>
    openstack security group rule create --protocol tcp \
        --dst-port=22:22 \
	--remote-ip 0.0.0.0/0 <uuid>

After running these commands you should be able to access the instance:

    ssh ubuntu@<new-floating-ip>

## What next?

Configuring and managing services on an OpenStack cloud is complex; take a look a the [OpenStack Admin Guide][] for a complete reference on how to configure an OpenStack cloud for your requirements.

## Useful Cloud URLs

 - OpenStack Dashboard: http://openstack-dashboard_ip/horizon

[MAAS]: https://maas.io/
[Simplestreams]: https://launchpad.net/simplestreams
[OpenStack Neutron]: http://docs.openstack.org/admin-guide-cloud/content/ch_networking.html
[OpenStack Admin Guide]: http://docs.openstack.org/user-guide-admin/content
[LXD]: https://linuxcontainers.org/lxd/
