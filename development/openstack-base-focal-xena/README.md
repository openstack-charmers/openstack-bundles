# Basic OpenStack cloud

**TESTING ONLY - This is a development bundle.** See the `stable` directory for
the stable bundles.

This `openstack-base` bundle deploys a base OpenStack cloud. Its major elements
include:

* Ubuntu 20.04 LTS (Focal)
* OpenStack Xena
* Ceph Pacific

Cloud services consist of Compute, Network, Block Storage, Object Storage,
Identity, Image, and Dashboard.

> **Note**: Modifications will typically need to be made to this bundle for it
  to work in your environment.

## Requirements

The bundle is primarily designed to work with [MAAS][maas] as a backing cloud
for Juju.

The MAAS cluster must have a minimum of four nodes:

* one for the Juju controller, with at least 1 CPU and 4 GiB memory

* three (ideally identical) for the actual cloud, with minimum resources
  being:

    * 8 GiB memory
    * enough CPU cores to support your workload
    * two disks
    * two cabled network interfaces

  The first disk is used for the node's operating system, and the second is for
  Ceph storage.

  The first network interface is used for communication between cloud services
  (East/West traffic), and the second is for network traffic between the cloud
  and all external networks (North/South traffic).

> **Note**: The smaller controller node can be targeted via Juju
  [constraints][juju-constraints-controller] at controller-creation time.

## Topology

* 3 MAAS nodes, with each hosting one of the following:
    * Ceph storage
    * Nova Compute
    * NTP

* LXD containers for the following (distributed among the 3 MAAS nodes):
    * Ceph monitors (x3)
    * Ceph RADOS Gateway
    * Cinder
    * Glance
    * Horizon
    * Keystone
    * MySQL8 (x3)
    * Neutron
    * Nova Cloud Controller
    * OVN (x3)
    * Placement
    * RabbitMQ
    * Vault

## Download the bundle

If not already done, clone the [openstack-bundles][openstack-bundles]
repository:

    git clone https://github.com/openstack-charmers/openstack-bundles

The stable and development bundles are found under the `stable/openstack-base`
and `development` directories respectively.

Overlay bundles are available under `stable/overlays`. See the Juju
documentation on [overlay bundles][juju-overlays].

## Modify the bundle

If using the stable openstack-base bundle, the file to modify is
`./stable/openstack-base/bundle.yaml`.

> **Tip**: Keep the master branch of the repository pristine and create a
  working branch to contain your modifications.

A `variables:` section is used for conveniently setting values in one place.
The third column contains the actual values.

    variables:
      openstack-origin:    &openstack-origin     cloud:focal-xena
      data-port:           &data-port            br-ex:eno2
      worker-multiplier:   &worker-multiplier    0.25
      osd-devices:         &osd-devices          /dev/sdb /dev/vdb
      expected-osd-count:  &expected-osd-count   3
      expected-mon-count:  &expected-mon-count   3

See the [Install OpenStack][cdg-install-openstack] page in the [OpenStack
Charms Deployment Guide][cdg] for help on understanding the variables (the
first column).

### Network spaces

If you're using MAAS and it contains network spaces you will need to bind them
to the applications being deployed. One way of doing this is with the
`openstack-base-spaces-overlay.yaml` overlay bundle. Like the main bundle file,
it will likely require tailoring:

    variables:
      public-space:        &public-space         public-space

See the Juju documentation on [network spaces][juju-spaces].

### Containerless

If you do not want to run containers you will need to undo the placement
directives that point to containers. One way of doing this is with the
`openstack-base-virt-overlay.yaml` overlay bundle.

## MAAS cloud, Juju controller, and model

Ensure that the MAAS cluster has been added to Juju as a cloud and that a Juju
controller has been created for that cloud. See the Juju documentation for
guidance: [Using MAAS with Juju][juju-and-maas].

Assuming the controller is called 'maas-controller', create a model called,
say, 'openstack' and give it the appropriate default series (e.g. focal):

    juju add-model -c maas-controller --config default-series=focal openstack

Now ensure that the new model is the current model:

    juju switch maas-controller:openstack

## Deploy the cloud

To install OpenStack, if you're using the spaces overlay:

    juju deploy ./bundle.yaml --overlay ./openstack-base-spaces-overlay.yaml

Otherwise, simply do:

    juju deploy ./bundle.yaml

If you're using a custom overlay (to override elements in earlier bundles)
simply append it to the command:

    juju deploy ./bundle.yaml --overlay ./custom-overlay.yaml
    juju deploy ./bundle.yaml --overlay ./openstack-base-spaces-overlay.yaml --overlay ./custom-overlay.yaml

> **Note**: Here it is assumed, for the sake of brevity, that the YAML files
  are in the current working directory.

### Issue TLS certificates

This bundle uses Vault to issue TLS certificates to services, and some
post-deployment steps are needed in order for it to work. Failure to complete
them, for example, will leave the OVN deployment with the following message (in
`juju status`):

    'ovsdb-*' incomplete, 'certificates' awaiting server certificate data

See to the [Vault charm README][vault-charm-post-deploy] for instructions.

## Install the OpenStack clients

You'll need the OpenStack clients in order to manage your cloud from the
command line. Install them now:

    sudo snap install openstackclients --classic

## Access the cloud

Confirm that you can access the cloud from the command line:

    source ~/openstack-bundles/stable/openstack-base/openrc
    openstack service list

You should get a listing of all registered cloud services.

## Import an image

You'll need to import an image into Glance in order to create instances.

First download a boot image, like Focal amd64:

    curl http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img \
       --output ~/cloud-images/focal-amd64.img

Now import the image and call it 'focal-amd64':

    openstack image create --public --container-format bare \
       --disk-format qcow2 --file ~/cloud-images/focal-amd64.img \
       focal-amd64

Images for other Ubuntu releases and architectures can be obtained in a similar
way.

For the ARM 64-bit (arm64) architecture you will need to configure the image to
boot in UEFI mode:

    curl http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img \
       --output ~/cloud-images/focal-arm64.img

    openstack image create --public --container-format bare \
       --disk-format qcow2 --property hw_firmware_type=uefi \
       --file ~/cloud-images/focal-arm64.img \
       focal-arm64

## Configure networking

For the purposes of a quick test, we'll set up an external network and a
shared router ('provider-router') that will be used by all tenants for public
access to instances.

For an example private cloud, create a network ('ext_net'):

    openstack network create --external \
       --provider-network-type flat --provider-physical-network physnet1 \
       ext_net

When creating the external subnet ('ext_subnet') the actual values used will
depend on the environment that the second network interface (on all nodes) is
connected to:

    openstack subnet create --network ext_net --no-dhcp \
       --gateway 10.0.0.1 --subnet-range 10.0.0.0/21 \
       --allocation-pool start=10.0.0.10,end=10.0.0.200 \
       ext_subnet

> **Note**: For a public cloud the ports would be connected to a publicly
  addressable part of the internet.

We'll also need an internal network ('int_net'), subnet ('int_subnet'), and
router ('provider-router'):

    openstack network create int_net

    openstack subnet create --network int_net --dns-nameserver 8.8.8.8 \
       --gateway 192.168.0.1 --subnet-range 192.168.0.0/24 \
       --allocation-pool start=192.168.0.10,end=192.168.0.200 \
       int_subnet

    openstack router create provider-router
    openstack router set --external-gateway ext_net provider-router
    openstack router add subnet provider-router int_subnet

See the [Neutron documentation][openstack-neutron] for more information.

## Create a flavor

Create at least one flavor to define a hardware profile for new instances. Here
we create one called 'm1.small':

    openstack flavor create --ram 2048 --disk 20 --ephemeral 20 m1.small

Make sure that your MAAS nodes can accommodate the flavor's resources.

## Import an SSH keypair

An SSH keypair needs to be imported into the cloud in order to access your
instances.

Generate one first if you do not yet have one. This command creates a
passphraseless keypair (remove the `-N` option to avoid that):

    ssh-keygen -q -N '' -f ~/cloud-keys/id_mykey

To import a keypair:

    openstack keypair create --public-key ~/cloud-keys/id_mykey.pub mykey

## Configure security groups

To allow ICMP (ping) and SSH traffic to flow to cloud instances create
corresponding rules for each existing security group:

    for i in $(openstack security group list | awk '/default/{ print $2 }'); do
       openstack security group rule create $i --protocol icmp --remote-ip 0.0.0.0/0;
       openstack security group rule create $i --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 22;
    done

You only need to perform this step once.

## Create an instance

Create a Focal amd64 instance called 'focal-1':

    openstack server create --image focal-amd64 --flavor m1.small \
       --key-name mykey --network int_net \
        focal-1

## Assign a floating IP address

Request and assign a floating IP address to the new instance:

    FLOATING_IP=$(openstack floating ip create -f value -c floating_ip_address ext_net)
    openstack server add floating ip focal-1 $FLOATING_IP

## Log in to an instance

Log in to the new instance:

    ssh -i ~/cloud-keys/id_mykey ubuntu@$FLOATING_IP

The below commands are a good start to troubleshooting if something goes wrong:

    openstack console log show focal-1
    openstack server show focal-1

## Access the cloud dashboard

To access the dashboard (Horizon) first obtain its IP address:

    juju status --format=yaml openstack-dashboard | grep public-address | awk '{print $2}' | head -1

In this example, the address is '10.0.0.30'.

The password can be queried from Keystone:

    juju run --unit keystone/leader leader-get admin_passwd

The dashboard URL then becomes:

**http://10.0.0.30/horizon**

The final credentials needed to log in are:

<!-- There are two spaces at the end of the next two lines -->

User Name: **admin**  
Password: ********************  
Domain: **admin_domain**

### VM consoles

Enable a remote access protocol such as `novnc` (or `spice`) if you want to
connect to VM consoles from within the dashboard:

    juju config nova-cloud-controller console-access-protocol=novnc

## Further reading

The below resources are recommended for further reading:

* [OpenStack Administrator Guides][openstack-admin-guides]: for upstream
  OpenStack administrative help
* [OpenStack Charms Deployment Guide][cdg]: for charm usage information

<!-- LINKS -->

[maas]: http://maas.io/docs
[OpenStack Neutron]: http://docs.openstack.org/admin-guide-cloud/content/ch_networking.html
[OpenStack Admin Guide]: http://docs.openstack.org/user-guide-admin/content
[Ubuntu Cloud Images]: http://cloud-images.ubuntu.com/focal/current/
[cdg]: https://docs.openstack.org/project-deploy-guide/charm-deployment-guide/xena/
[cdg-install-openstack]: https://docs.openstack.org/project-deploy-guide/charm-deployment-guide/xena/install-openstack.html
[openstack-bundles]: https://github.com/openstack-charmers/openstack-bundles
[juju-overlays]: https://jaas.ai/docs/charm-bundles#heading--overlay-bundles
[juju-spaces]: https://jaas.ai/docs/spaces
[juju-constraints-controller]: https://jaas.ai/docs/constraints#heading--setting-constraints-for-a-controller
[juju-and-maas]: https://jaas.ai/docs/maas-cloud
[vault-charm-post-deploy]: https://opendev.org/openstack/charm-vault/src/branch/master/src/README.md#post-deployment-tasks
[openstack-neutron]: https://docs.openstack.org/neutron/
[openstack-admin-guides]: http://docs.openstack.org/admin
