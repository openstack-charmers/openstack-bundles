#!/bin/bash -uex
# A light validation of the resultant ceph cluster, and juju model artifact collection

juju run --all "uname -a"                           | tee    ceph-mon-basic-validation.txt
juju run --application ceph-mon "sudo ceph -s"      | tee -a ceph-mon-basic-validation.txt
juju-crashdump  # See https://github.com/juju/juju-crashdump

