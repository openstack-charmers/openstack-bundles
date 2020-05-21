# Basic OpenStack cloud

The `openstack-base` bundle currently deploys a basic OpenStack cloud with
these foundational elements:

- Ubuntu 20.04 LTS (Focal)
- OpenStack Ussuri
- Ceph Octopus

## Requirements
This example bundle is designed to run on bare metal using Juju 2.x with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 4 physical servers prior to using this bundle.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

For example, a section similar to this exists in the bundle.yaml file.  The third "column" are the values to set.  Some servers may not have eno2, they may have something like eth2 or some other network device name.  This needs to be adjusted prior to deployment.  The same principle holds for osd-devices.  The third column is a whitelist of devices to use for Ceph OSDs.  Adjust accordingly by editing bundle.yaml before deployment.

```
variables:
  openstack-origin:    &openstack-origin     distro
  data-port:           &data-port            br-ex:eno2
  worker-multiplier:   &worker-multiplier    0.25
  osd-devices:         &osd-devices          /dev/sdb /dev/vdb
```

Servers should have:

 - A minimum of 8GB of physical RAM.
 - Enough CPU cores to support your capacity requirements.
 - Two disks (identified by /dev/sda and /dev/sdb); the first is used by MAAS for the OS install, the second for Ceph storage.
 - Two cabled network ports on eno1 and eno2 (see below).

Servers should have two physical network ports cabled; the first is used for general communication between services in the Cloud, the second is used for 'public' network traffic to and from instances (North/South traffic) running within the Cloud.


> **Important**: The three MAAS nodes are needed for the actual OpenStack cloud;
  they do not include the Juju controller. You actually need a minimum of four 
  nodes. The controller node however can be a smaller system (1 CPU and 4 GiB
  memory). Juju [constraints][juju-constraints] (e.g. 'tags') can be used to
  target this smaller system at controller-creation time.

## Components

 - 3 Nodes for Nova Compute and Ceph, with RabbitMQ, MySQL, Keystone, Glance, Neutron, OVN, Nova Cloud Controller, Ceph RADOS Gateway, Cinder and Horizon under LXC containers.

All physical servers (not LXC containers) will also have NTP installed and configured to keep time in sync.

## Download the bundle

Modifications will typically need to be made to this bundle for it to work in
your environment. You will also require access to a credentials/init file.

The Charm Tools allow you to download charms and bundles from the Charm Store.
Install them now and then download the bundle:

    sudo snap install charm --classic
    charm pull openstack-base ~/openstack-base

## Network spaces and overlays

If the MAAS cluster contains network spaces you will need to bind them to the
applications to be deployed. One way of doing this is with the
`openstack-base-spaces-overlay.yaml` overlay bundle that ships with the bundle.

Like the main bundle file, it will likely require tailoring. The file employs
the variable method of assigning values. The actual space name should be the
far-right value on this line:

    variables:
      public-space:        &public-space         public-space

The [`openstack-bundles`][openstack-bundles] repository contains more example
overlay bundles.

See the Juju documentation on [network spaces][juju-spaces] and [overlay
bundles][juju-overlays] for background information.

## MAAS cloud and Juju controller

Ensure that the MAAS cluster has been added to Juju as a cloud and that a Juju
controller has been created for that cloud. See the Juju documentation for
guidance: [Using MAAS with Juju][juju-and-maas].

Assuming the controller is called 'maas-controller' and you want to use the
empty model 'default', change to that context:

    juju switch maas-controller:default

## Deploy the cloud

First move into the bundle directory:

    cd ~/openstack-base

To install OpenStack use this command if you're using the spaces overlay:

    juju deploy ./bundle.yaml --overlay ./openstack-base-spaces-overlay.yaml

Otherwise, simply do:

    juju deploy ./bundle.yaml

## Install the OpenStack clients

You'll need the OpenStack clients in order to manage your cloud from the
command line. Install them now:

    sudo snap install openstackclients

## Unseal vault

This release uses vault to secure keystone - vault needs to be unsealed before the configuration
can be finalised and the cloud used. See the following documentation for unseal steps:

[Unsealing vault][vault-appendix]

## Access the cloud

Confirm that you can access your cloud from the command line:

    source ~/openstack-base/openrc
    openstack service list

You should get a listing of all registered cloud services.

## Import an image

You'll need to import a boot image in order to create instances. Here we
import a Bionic amd64 image and call it 'bionic':

    curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img | \
        openstack image create --public --container-format=bare --disk-format=qcow2 \
        bionic

Images for other Ubuntu releases and architectures can be obtained in a similar
way.

For the ARM 64-bit (arm64) architecture you will need to configure the image to
boot in UEFI mode:

    curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-arm64.img | \
        openstack image create --public --container-format=bare --disk-format=qcow2 \
        --property hw_firmware_type=uefi bionic

## Configure networking

Networking will be configured with the aid of two scripts supplied by
the bundle.

> **Note**: These scripts are written for Python 2 and may not work on a modern
  system without first installing the ``python-keystoneclient`` and
  ``python-neutronclient`` deb packages.

For the "external" network a shared router ('provider-router') will be used by
all tenants for public access to instances. The syntax is:

    ./neutron-ext-net-ksv3 --network-type flat \
        -g <gateway-ip> -c <network-cidr> \
        -f <pool-start>:<pool-end> <network-name>

In a public cloud the values would correspond to a publicly addressable part of
the internet. Here, we'll configure for a private cloud. The actual values will
depend on the environment that the second network interface (on all the nodes)
is connected to. For example:

    ./neutron-ext-net-ksv3 --network-type flat \
        -g 10.230.168.1 -c 10.230.168.0/21 \
        -f 10.230.168.10:10.230.175.254 ext_net

For the "internal" tenant network, to which the instances are actually
connected, the syntax is:

    ./neutron-tenant-net-ksv3 -p <project> -r <router> \
        [-N <dns-nameservers>] <network-name> <network-cidr>

For example:

    ./neutron-tenant-net-ksv3 -p admin -r provider-router internal 10.5.5.0/24

See the [Neutron documentation][openstack-neutron] for more information.

## Create a flavor

Create at least one flavor to define a hardware profile for new instances. Here
we create one called 'm1.tiny':

    openstack flavor create --ram 1024 --disk 6 m1.tiny

The above flavor is defined with minimum specifications. If you use larger
values ensure that your compute nodes have the resources to accommodate them.

## Import an SSH keypair

An SSH keypair needs to be imported into the cloud in order to access your
instances.

Generate one first if you do not yet have one. This command creates a
passphraseless keypair (remove the `-N` option to avoid that):

    ssh-keygen -q -N '' -f ~/.ssh/id_mykey

To import a keypair:

    openstack keypair create --public-key ~/.ssh/id_mykey.pub mykey

## Configure security groups

To allow ICMP (ping) and SSH traffic to flow to cloud instances create
corresponding rules for each security group:

    for i in $(openstack security group list | awk '/default/{ print $2 }'); do
        openstack security group rule create $i --protocol icmp --remote-ip 0.0.0.0/0;
        openstack security group rule create $i --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 22;
	done

You only need to perform this step once.

## Create an instance

To create a Bionic instance called 'bionic-1':

    openstack server create --image bionic --flavor m1.tiny --key-name mykey \
        --nic net-id=$(openstack network list | grep internal | awk '{ print $2 }') \
        bionic-1

## Attach a volume

This step is optional.

To create a 10GiB volume in Cinder and attach it to the new instance:

    openstack volume create --size=10 <volume-name>
    openstack server add volume bionic-1 <volume-name>

The volume becomes immediately available to the instance. It will however need
to be formatted and mounted before usage.

## Assign a floating IP address

To request and assign a floating IP address:

    FLOATING_IP=$(openstack floating ip create -f value -c floating_ip_address ext_net)
    openstack server add floating ip bionic-1 $FLOATING_IP

## Log in to an instance

To log in to the new instance:

    ssh -i ~/.ssh/id_mykey ubuntu@$FLOATING_IP

## Access the cloud dashboard

The cloud dashboard (Horizon) can be accessed by going to:

`http://<openstack-dashboard-ip>/horizon`

The IP address is taken from the output to:

    juju status openstack-dashboard

Print the credentials in this way:

    echo -e "Domain: $OS_USER_DOMAIN_NAME\nUser Name: $OS_USERNAME\nPassword: $OS_PASSWORD"

If that does not work then source the `openrc` file and try again:

    source ~/openstack-base/openrc

## Scale the cloud

The neutron-gateway, nova-compute, and ceph-osd applications are designed to be
horizontally scalable.

To scale nova-compute:

    juju add-unit nova-compute # Add one more unit
    juju add-unit -n5 nova-compute # Add 5 more units

To scale ceph-osd:

    juju add-unit ceph-osd # Add one more unit
    juju add-unit -n50 ceph-osd # add 50 more units

The ceph-osd application can also be scaled by placing units on the same
machine where either the nova-compute units currently reside. This can be done
via a "placement directive" (the `--to` option):

    juju add-unit --to <machine-id> ceph-osd

Other applications in this bundle can be used in conjunction with the
[`hacluster`][hacluster-charm] subordinate charm to produce scalable, highly
available cloud services.

## Next steps

Configuring and managing services for an OpenStack cloud is complex. See the
[OpenStack Administrator Guides][openstack-admin-guides] for help.

<!-- LINKS -->

[hacluster-charm]: https://jaas.ai/hacluster
[maas]: https://maas.io/
[overlays]: https://github.com/openstack-charmers/openstack-bundles/tree/master/stable/overlays
[spaces-overlay]: https://github.com/openstack-charmers/openstack-bundles/blob/master/stable/overlays/openstack-base-spaces-overlay.yaml
[juju-and-maas]: https://jaas.ai/docs/maas-cloud
[juju-constraints]: https://jaas.ai/docs/constraints#heading--setting-constraints-for-a-controller
[juju-overlays]: https://jaas.ai/docs/charm-bundles#heading--overlay-bundles
[juju-spaces]: https://jaas.ai/docs/spaces
[openstack-neutron]: https://docs.openstack.org/neutron/
[openstack-admin-guides]: http://docs.openstack.org/admin
[openstack-bundles]: https://github.com/openstack-charmers/openstack-bundles/tree/master/stable/overlays
[ubuntu-cloud-images]: http://cloud-images.ubuntu.com
[vault-appendix]: https://docs.openstack.org/project-deploy-guide/charm-deployment-guide/latest/app-vault.html

