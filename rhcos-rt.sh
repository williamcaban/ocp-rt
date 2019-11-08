#!/bin/bash

export WEBROOT_RT="http://198.18.100.1:8000/RHEL-8.1-RT/"

# storing rpms in /root in case needed again
cd /root

curl -s -O ${WEBROOT_RT}/Packages/kernel-rt-core-4.18.0-147.rt24.93.el8.x86_64.rpm
curl -s -O ${WEBROOT_RT}/Packages/kernel-rt-modules-4.18.0-147.rt24.93.el8.x86_64.rpm
curl -s -O ${WEBROOT_RT}/Packages/kernel-rt-modules-extra-4.18.0-147.rt24.93.el8.x86_64.rpm

echo "Applying patched microcode_ctl"
# patched microcode_ctl required (pre-alpha)
rpm-ostree override replace https://fedorapeople.org/~walters/microcode_ctl-20190918-3.rhcos.1.el8.x86_64.rpm

echo "Applying RT Kernel"
# create override layer
rpm-ostree override remove kernel{,-core,-modules,-modules-extra} \
--install kernel-rt-core-4.18.0-147.rt24.93.el8.x86_64.rpm \
--install kernel-rt-modules-4.18.0-147.rt24.93.el8.x86_64.rpm \
--install kernel-rt-modules-extra-4.18.0-147.rt24.93.el8.x86_64.rpm 