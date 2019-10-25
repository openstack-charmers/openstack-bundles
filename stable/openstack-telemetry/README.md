# OpenStack Telemetry

This example bundle extends the basic OpenStack Cloud bundle with Telemetry collection via Ceilometer.

Certain configuration options within the bundle may need to be adjusted prior to deployment to fit your particular set of hardware. For example, network device names and block device names can vary, and passwords should be yours.

For full details on the base cloud deployment please refer to the [Basic OpenStack Cloud][] bundle.

[Basic OpenStack Cloud]: http://jujucharms.com/openstack-base

## Deployment


### Deploy latest charms with OpenStack in Bionic main

```
juju deploy ./bundle.yaml \
  --overlay openstack-telemetry-overlay.yaml
```

### Deploy with specific version of the charms and a specific OpenStack version

```
juju deploy ./bundle.yaml \
  --overlay openstack-telemetry-overlay.yaml \
  --overlay 19.10-bionic-train-openstack-telemetry-overlay.yaml
```


### Deploy with specific version of the charms and a specific OpenStack version specifying MAAS spaces

```
juju deploy ./bundle.yaml \
  --overlay openstack-telemetry-overlay.yaml \
  --overlay 19.10-bionic-train-openstack-telemetry-overlay.yaml \
  --overlay openstack-telemetry-spaces-overlay.yaml
```
