# OpenStack Converged Networking

*DEV/TEST ONLY*: This unstable, development example bundle extends the basic OpenStack Cloud bundle with Telemetry collection via Ceilometer. See also: [Stable Bundles](https://jujucharms.com/u/openstack-charmers).

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

For full details on the base cloud deployment please refer to the [Basic OpenStack Cloud][] bundle.

## Requirements

This example bundle is designed to run on bare metal using Juju 2.x with [MAAS][] (Metal-as-a-Service); you will need to have setup a [MAAS][] deployment with a minimum of 3 physical servers prior to using this bundle.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

For example, a section similar to this exists in the bundle.yaml file.  The third "column" are the values to set.  Some servers may not have bond0, they may have something like eth2 or some other network device name.  This needs to be adjusted prior to deployment.  The same principle holds for osd-devices.  The third column is a whitelist of devices to use for Ceph OSDs.  Adjust accordingly by editing bundle.yaml before deployment.

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

# Configuration

The key configuration item is data-port. This must match what has been configured in MAAS for the physical host. Both the bridge name (using the OpenVSwitch type), br-ex, and the bond name, bond0.

The spaces configuration is also significant if the spaces defined have different names in the deployed MAAS.

# Usage

juju deploy ./bundle.yaml --overlay openstack-superbond-spaces-overlay.yaml

