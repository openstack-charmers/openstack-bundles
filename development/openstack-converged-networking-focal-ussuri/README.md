# OpenStack Converged Networking

*DEV/TEST ONLY*: This unstable, development example bundle is used to test and demonstrate a baremetal deployment of OpenStack on [MAAS][] using a single network card for the host.

The converged networking "superbond" concept is a single interface on a physical host that is used for the host's communication, OpenVSwitch's communication and bridges for LXD container communication. Previously it was necessary to dedicate an entire physical interface to OpenVSwitch therefore requiring multiple interfaces on the physical host. OVS would completely own the physical interface thus eliminating it for use in any other purpose. The converged networking solution uses a single physical interface for all communication traffic managed by OpenVSwitch.

## Requirements

This example bundle is designed to run on bare metal using Juju >=2.9 with [MAAS][] (Metal-as-a-Service) >=2.9; you will need to have setup a [MAAS][] deployment with a minimum of 3 physical servers prior to using this bundle.

Converged networking is accomplished by configuring the networking for the physical host in [MAAS][] to use Openvswitch for its bridge set up [MAAS Docs](https://maas.io/docs/deb/2.9/ui/networking). The physical interface for the bridge may be a bond. Any number of VLANs may be added to the bridge to accommodate network spaces.

The key configuration item in the bundle is `data-port`. This must match what has been configured in [MAAS][] for the physical host. Both the bridge name (using the OpenVSwitch type), br-ex, and the bond name, bond0.

Spaces configuration is also significant. The names of spaces must match what is configured in [MAAS][]

```
variables:
  openstack-origin:    &openstack-origin     distro
  data-port:           &data-port            br-ex:bond0
  worker-multiplier:   &worker-multiplier    0.25
  osd-devices:         &osd-devices          /dev/sdb /dev/vdb
```

Spaces definitions in openstack-superbond-spaces-overlay.yaml

```
variables:
  public-space:        &public-space         public
  internal-space:        &internal-space         internal
  admin-space:        &admin-space         admin
```

# Usage

juju deploy ./bundle.yaml --overlay openstack-superbond-spaces-overlay.yaml

