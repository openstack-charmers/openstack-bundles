# Basic OpenStack Cloud

This example bundle deploys a basic OpenStack Cloud (Stein with Ceph Mimic) on Ubuntu 18.04 LTS (Bionic), providing Dashboard, Compute, Network, Block Storage, Object Storage, Identity and Image services.

## Requirements

This example bundle is designed to run on bare metal using Juju 2.x with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 4 physical servers prior to using this bundle.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

In particular, set the following to the appropriate local values:

  ceph-osd:
    comment: SET osd-devices to match your environment
    options:
      osd-devices: /dev/sdb /dev/vdb

  neutron-gateway:
    comment: SET data-port to match your environment
    options:
      data-port: br-ex:eno2

> **Note**: We distribute [overlays](https://github.com/openstack-charmers/openstack-bundles/tree/master/stable/overlays)
  for use in conjunction with the example bundle.  If you want to make use of
  them, please review them for any configuration options that need tailoring to
  match your environment prior to deployment.

Servers should have:

 - A minimum of 8GB of physical RAM.
 - Enough CPU cores to support your capacity requirements.
 - Two disks (identified by /dev/sda and /dev/sdb); the first is used by MAAS for the OS install, the second for Ceph storage.
 - Two cabled network ports on eno1 and eno2 (see below).

Servers should have two physical network ports cabled; the first is used for general communication between services in the Cloud, the second is used for 'public' network traffic to and from instances (North/South traffic) running within the Cloud.

## Components

 - 1 Node for Neutron Gateway and Ceph with RabbitMQ and MySQL under LXC containers.
 - 3 Nodes for Nova Compute and Ceph, with Keystone, Glance, Neutron, Nova Cloud Controller, Ceph RADOS Gateway, Cinder and Horizon under LXC containers.

All physical servers (not LXC containers) will also have NTP installed and configured to keep time in sync.


## Deployment

With a Juju controller bootstrapped on a MAAS cloud with no network spaces
defined, a basic non-HA cloud can be deployed with the following command:

    juju deploy bundle.yaml

When network spaces exist in the MAAS cluster, it is necessary to clarify
and define the network space(s) to which the charm applications will deploy.
This can be done with an overlay bundle.  An example overlay yaml file is
provided, which most likely needs to be edited (before deployment) to
represent the intended network spaces in the existing MAAS cluster.  Example
usage:

    juju deploy bundle.yaml --overlay openstack-base-spaces-overlay.yaml

## Scaling

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

    sudo snap install openstackclients

### Accessing the cloud

Check that you can access your cloud from the command line:

    source openrc
    openstack catalog list

You should get a full listing of all services registered in the cloud which should include identity, compute, image and network.

### Configuring an image

In order to run instances on your cloud, you'll need to upload an image to boot instances:

    curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img | \
        openstack image create --public --container-format=bare --disk-format=qcow2 bionic

Images for other architectures can be obtained from [Ubuntu Cloud Images][].  Be sure to use the appropriate image for the cpu architecture.

**Note:** for ARM 64-bit (arm64) guests, you will also need to configure the image to boot in UEFI mode:

    curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-arm64.img | \
        openstack image create --public --container-format=bare --disk-format=qcow2 --property hw_firmware_type=uefi bionic

### Configure networking

In order to help with configuring the networking, the bundle includes two helper Python scripts:

* neutron-ext-net-ksv3
* neutron-tenant-net-ksv3

These are equivalent to running several `openstack` commands but wrap them up into a single script.  In order to actually run these scripts several python modules are needed and the easiest way to do this is to use a [pipenv](https://pipenv.readthedocs.io/en/latest/) environment to download the modules and made them available for the two scripts.

Install `pipenv` in your `--user` python environment (if it is not already set up):

    pip3 install --user pipenv

Be sure to read the [installation instructions of Pipenv](https://pipenv.readthedocs.io/en/latest/install/#installing-pipenv) to ensure you get a working environment.

After pipenv is installed, in the *same* directory as the `Pipfile`, run the following two commands:

    pipenv install
    pipenv shell

This will provide an environment in which to run the two scripts.

For the purposes of a quick test, we'll setup an 'external' network and shared router ('provider-router') which will be used by all tenants for public access to instances:

    ./neutron-ext-net-ksv3 --network-type flat \
        -g <gateway-ip> -c <network-cidr> \
        -f <pool-start>:<pool-end> ext_net

for example (for a private cloud):

    ./neutron-ext-net-ksv3 --network-type flat \
        -g 10.230.168.1 -c 10.230.168.0/21 \
        -f 10.230.168.10:10.230.175.254 ext_net

You'll need to adapt the parameters for the network configuration that eno2 on all the servers is connected to; in a public cloud deployment these ports would be connected to a publicly addressable part of the Internet.

We'll also need an 'internal' network for the admin user which instances are actually connected to:

    ./neutron-tenant-net-ksv3 -p admin -r provider-router \
        [-N <dns-server>] internal 10.5.5.0/24

Neutron provides a wide range of configuration options; see the [OpenStack Neutron][] documentation for more details.

### Configuring a flavor

Starting with the OpenStack Newton release, default flavors are no longer created at install time. You therefore need to create at least one machine type before you can boot an instance:

    openstack flavor create --ram 2048 --disk 20 --ephemeral 20 m1.small

### Booting an instance

First generate a SSH keypair so that you can access your instances once you've booted them:

    mkdir -p ~/.ssh
    touch ~/.ssh/id_rsa_cloud
    chmod 600 ~/.ssh/id_rsa_cloud
    openstack keypair create mykey > ~/.ssh/id_rsa_cloud

**Note:** you can also upload an existing public key to the cloud rather than generating a new one:

    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

You can now boot an instance on your cloud:

    openstack server create --image bionic --flavor m1.small --key-name mykey \
        --nic net-id=$(openstack network list | grep internal | awk '{ print $2 }') \
        bionic-test

### Attaching a volume

First, create a 10G volume in cinder:

    openstack volume create --size=10 <name-of-volume>

then attach it to the instance we just booted:

    openstack server add volume bionic-test <name-of-volume>

The attached volume will be accessible once you login to the instance (see below).  It will need to be formatted and mounted!

### Accessing your instance

In order to access the instance you just booted on the cloud, you'll need to assign a floating IP address to the instance:

    openstack floating ip create ext_net
    openstack server add floating ip bionic-test <new-floating-ip>

and then allow access via SSH (and ping) - you only need to do these steps once:

    openstack security group list

For each security group in the list, identify the UUID and run:


    openstack security group rule create <uuid> \
        --protocol icmp --remote-ip 0.0.0.0/0

    openstack security group rule create <uuid> \
        --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 22

After running these commands you should be able to access the instance:

    ssh ubuntu@<new-floating-ip>

## What next?

Configuring and managing services on an OpenStack cloud is complex; take a look a the [OpenStack Admin Guide][] for a complete reference on how to configure an OpenStack cloud for your requirements.

## Useful Cloud URLs

 - OpenStack Dashboard: http://openstack-dashboard_ip/horizon

[MAAS]: http://maas.ubuntu.com/docs
[Simplestreams]: https://launchpad.net/simplestreams
[OpenStack Neutron]: http://docs.openstack.org/admin-guide-cloud/content/ch_networking.html
[OpenStack Admin Guide]: http://docs.openstack.org/user-guide-admin/content
[Ubuntu Cloud Images]: http://cloud-images.ubuntu.com/bionic/current/
