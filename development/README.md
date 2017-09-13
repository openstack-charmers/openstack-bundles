#### Pushing Bundles to the Charm Store

```
snap install charm
```

The charm tool doesn't follow symlinks. Copy and dereference.
```
cp -Lrfv open openstack-refstack-xenial-ocata ~/temp/openstack-refstack-xenial-ocata
```

After pushing, a unique CS url will be returned, use that below in the release and grant commands
```
charm push ./openstack-refstack-xenial-ocata
```

Allow the world to see it
```
charm release cs:~openstack-charmers-next/bundle/openstack-refstack-xenial-ocata-NNNN
```
```
charm grant cs:~openstack-charmers-next/bundle/openstack-refstack-xenial-ocata-NNNN --acl read everyone
```

View it in the [Juju Charm Store](https://jujucharms.com/u/openstack-charmers-next/).

