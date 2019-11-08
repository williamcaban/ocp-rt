# OCP 4.3: Enabling real-time worker (RHCOS-RT)

```
####################################################
# NOTE: WORK IN PROGRESS. UNSUPPORTED PROCEDURE.
####################################################
```

## Setup local web server as RPM and script repos

**NOTE:** Instructions assuming `rhel-8.1-x86_64-dvd-main.iso` is the RHEL DVD with BaseOS and AppStream repos and `rhel-8.1-x86_64-dvd-rt.iso` is the RHEL DVD with the RT repos.

- Setup local repo from RHEL-RT 8.1 DVD
    ```
    mkdir /tmp/RHEL-8.1-RT
    mount -o loop,ro /root/rhel-8.1-x86_64-dvd-rt.iso /tmp/RHEL-8.1-RT 

    mkdir -pv /opt/nginx/html/RHEL-8.1-RT
    cp -afZ /tmp/RHEL-8.1-RT/. /opt/nginx/html/RHEL-8.1-RT/
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/RHEL-8.1-RT/

    umount /tmp/RHEL-8.1-RT
    ````

- (optional) Setup local repo from RHEL 8.1 DVD:
    ```
    mkdir /tmp/RHEL-8.1
    mount -o loop,ro /root/rhel-8.1-x86_64-dvd-main.iso /tmp/RHEL-8.1

    mkdir -pv /opt/nginx/html/RHEL-8.1
    cp -afZ /tmp/RHEL-8.1/. /opt/nginx/html/RHEL-8.1/
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/RHEL-8.1/

    umount /tmp/RHEL-8.1
    ```

## Prepare RHCOS override script

- Edit `rhcos-rt.sh` and set the `WEBROOT_RT` environment variable:
    ```
    vi ./rhcos-rt.sh 
    ```

- Copy script to WEBROOT
    ```
    cp ./rhcos-rt.sh /opt/nginx/html/
    ```

## Override RHCOS into RHCOS-RT
- Login to the node to convert into RT node (example using "worker-3"):
    ```
    # oc debug node/worker-3.ocp4poc.lab.shift.zone
    Starting pod/worker-3ocp4poclabshiftzone-debug ...
    To use host binaries, run `chroot /host`
    Pod IP: 198.18.100.18
    If you don't see a command prompt, try pressing enter.

    sh-4.2# chroot /host

    sh-4.4# curl -s http://198.18.100.1:8000/rhcos-rt.sh | bash
    Applying patched microcode_ctl
    Downloading 'https://fedorapeople.org/~walters/microcode_ctl-20190918-3.rhcos.1.el8.x86_64.rpm'... done!
    Checking out tree c3df460... done
    Enabled rpm-md repositories:
    Importing rpm-md... done
    Resolving dependencies... done
    Applying 1 override
    Processing packages... done
    Running pre scripts... done
    Running post scripts... done
    Running posttrans scripts... done
    Writing rpmdb... done
    Writing OSTree commit... done
    Staging deployment... done
    Upgraded:
    microcode_ctl 4:20190618-1.20190918.2.el8_1 -> 4:20190918-3.rhcos.1.el8
    Run "systemctl reboot" to start a reboot
    Applying RT Kernel
    Checking out tree c3df460... done
    Enabled rpm-md repositories:
    Importing rpm-md... done
    Resolving dependencies... done
    Applying 5 overrides and 3 overlays
    Processing packages... done
    Running pre scripts... done
    Running post scripts... done
    Running posttrans scripts... done
    Writing rpmdb... done
    Generating initramfs... done
    Writing OSTree commit... done
    Staging deployment... done
    Freed: 36.1 MB (pkgcache branches: 2)
    Upgraded:
    microcode_ctl 4:20190618-1.20190918.2.el8_1 -> 4:20190918-3.rhcos.1.el8
    Removed:
    kernel-4.18.0-147.el8.x86_64
    kernel-core-4.18.0-147.el8.x86_64
    kernel-modules-4.18.0-147.el8.x86_64
    kernel-modules-extra-4.18.0-147.el8.x86_64
    Added:
    kernel-rt-core-4.18.0-147.rt24.93.el8.x86_64
    kernel-rt-modules-4.18.0-147.rt24.93.el8.x86_64
    kernel-rt-modules-extra-4.18.0-147.rt24.93.el8.x86_64
    Run "systemctl reboot" to start a reboot

    sh-4.4# rpm-ostree status
    State: idle
    AutomaticUpdates: disabled
    Deployments:
    pivot://registry.svc.ci.openshift.org/ocp/4.3-2019-11-05-194939@sha256:3467568ce4f4cc41f29c1e1eef8c72ed188f940d923e0cb94b705d1599af3123
                CustomOrigin: Managed by machine-config-operator
                    Version: 43.81.201911051743.0 (2019-11-05T17:48:00Z)
                        Diff: 1 upgraded, 4 removed, 3 added
        RemovedBasePackages: kernel-core kernel-modules kernel kernel-modules-extra 4.18.0-147.el8
        ReplacedBasePackages: microcode_ctl 4:20190618-1.20190918.2.el8_1 -> 4:20190918-3.rhcos.1.el8
                LocalPackages: kernel-rt-modules-4.18.0-147.rt24.93.el8.x86_64 kernel-rt-core-4.18.0-147.rt24.93.el8.x86_64 kernel-rt-modules-extra-4.18.0-147.rt24.93.el8.x86_64

    * pivot://registry.svc.ci.openshift.org/ocp/4.3-2019-11-05-194939@sha256:3467568ce4f4cc41f29c1e1eef8c72ed188f940d923e0cb94b705d1599af3123
                CustomOrigin: Managed by machine-config-operator
                    Version: 43.81.201911051743.0 (2019-11-05T17:48:00Z)

    pivot://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4e5cb300ff5a9bee07685b3fd152cb10f26f386bc89f20aad19c3e8fc0dd704a
                CustomOrigin: Image generated via coreos-assembler
                    Version: 42.80.20190828.2 (2019-08-28T13:52:49Z)
    sh-4.4#

    sh-4.4# systemctl reboot
    sh-4.4# exit
    sh-4.2#
    Removing debug pod ...
    #
    ```

- After the reboot the worker should report output similar to this:
    ```
    sh-4.4# rpm-ostree status
    State: idle
    AutomaticUpdates: disabled
    Deployments:
    * pivot://registry.svc.ci.openshift.org/ocp/4.3-2019-11-05-194939@sha256:3467568ce4f4cc41f29c1e1eef8c72ed188f940d923e0cb94b705d1599af3123
                CustomOrigin: Managed by machine-config-operator
                    Version: 43.81.201911051743.0 (2019-11-05T17:48:00Z)
        RemovedBasePackages: kernel-core kernel-modules kernel kernel-modules-extra 4.18.0-147.el8
        ReplacedBasePackages: microcode_ctl 4:20190618-1.20190918.2.el8_1 -> 4:20190918-3.rhcos.1.el8
                LocalPackages: kernel-rt-modules-4.18.0-147.rt24.93.el8.x86_64 kernel-rt-core-4.18.0-147.rt24.93.el8.x86_64 kernel-rt-modules-extra-4.18.0-147.rt24.93.el8.x86_64

    pivot://registry.svc.ci.openshift.org/ocp/4.3-2019-11-05-194939@sha256:3467568ce4f4cc41f29c1e1eef8c72ed188f940d923e0cb94b705d1599af3123
                CustomOrigin: Managed by machine-config-operator
                    Version: 43.81.201911051743.0 (2019-11-05T17:48:00Z)
    sh-4.4#
    sh-4.4# uname -a
    Linux worker-3.ocp4poc.lab.shift.zone 4.18.0-147.rt24.93.el8.x86_64 #1 SMP PREEMPT RT Thu Sep 26 16:48:43 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
    sh-4.4#
    ```

## Prepare OpenShift for RT worker nodes

- Create OCP MCP, Tuned Profiles, MachineConfigs and KubeletConfigs
    ```
    oc create -f 00-mcp-worker-rt.yaml
    oc create -f 00-tuned-network-latency.yaml
    oc create -f 01-tuned-rt.yaml
    oc create -f 05-mc-rt.yaml
    oc create -f 05-kubeletconfig-worker-rt.yaml
    ```
- **NOTE:** Due to a bug, for now we need to label the `worker` MCP to receive the KubeletConfig so that `worker-rt` can have it
    ```
    oc label machineconfigpool worker worker-rt=""
    ```

- Apply RT profile profile to a Node
    ```
    oc label node <node_name> node-role.kubernetes.io/worker-rt=""
    ```
- After the MCP is applied the node will reboot

## RHCOS-RT Validations

- Validate the desired worker node has the desired worker-rt role:
    ```
    # oc get nodes
    NAME                              STATUS   ROLES              AGE   VERSION
    master-0.ocp4poc.exmple.com   Ready    master,worker      25h   v1.16.2
    master-1.ocp4poc.exmple.com   Ready    master,worker      25h   v1.16.2
    master-2.ocp4poc.exmple.com   Ready    master,worker      25h   v1.16.2
    worker-0.ocp4poc.exmple.com   Ready    worker             25h   v1.16.2
    worker-1.ocp4poc.exmple.com   Ready    worker             25h   v1.16.2
    worker-3.ocp4poc.exmple.com   Ready    worker,worker-rt   25h   v1.16.2
    ```

- Validate the MCP shows the desired machine count:
    ```
    oc get mcp
    NAME        CONFIG                                                UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT
    master      rendered-master-3d75b71ec284fa7d862bfe5f8794a524      True      False      False      3              3                   3                     0
    worker      rendered-worker-ee410243cca84cef5b4c0c8a40681b96      True      False      False      2              2                   2                     0
    worker-rt   rendered-worker-rt-5da79e09ba7db4d27ff50a91f7e5eab6   True      False      False      1              1                   1                     0
    ```

- Login into the worker-rt node and validate the correct Kernel arguments have been applied:
    ```
    sh-4.4# cat /proc/cmdline
    BOOT_IMAGE=/ostree/rhcos-02a1645a0b585894d46cfa6462693de7e97d59dbdb14383663019a2f301a62f3/vmlinuz-4.18.0-147.rt24.93.el8.x86_64 console=tty0 console=ttyS0,115200n8 rootflags=defaults,prjquota rw root=UUID=6101ba79-239a-439e-b891-6315c6c4b7bd ostree=/ostree/boot.1/rhcos/02a1645a0b585894d46cfa6462693de7e97d59dbdb14383663019a2f301a62f3/0 coreos.oem.id=metal ignition.platform.id=metal default_hugepagesz=1G hugepagesz=1G hugepages=32 nohz=on nosoftlockup nmi_watchdog=0 audit=0 mce=off kthread_cpus=0 irqaffinity=0 skew_tick=1 processor.max_cstate=1 idle=poll intel_pstate=disable intel_idle.max_cstate=0 intel_iommu=on iommu=pt
    sh-4.4#
    ```

# Demo RT workload

Sample setup: 32 cores
- 1 for kubelet
- 2 for system
- 4 for cyclictest
- 25 for stress-ng

*Note on `isolcpus`:* The `isolcpus` is good if every workload on the worker is defined using guaranteed class. Otherwise, eerything goes to the non-isolated cores and the performance drop. For this reason, these tests do not use `isolcpus` and instead rely on CPU Manager for the proper behavior by using the Kubelet flags `--kube-reserved 1 --system-reserved 1`.


- Create demo project and prepare to run the `cyclictest`:
    ```
    oc create ns demo-rt
    oc project demo-rt

    oc adm policy add-scc-to-user privileged -z default

    oc create -f 07-rt-stress-ng.yaml

    # oc get pods
    NAME                      READY   STATUS    RESTARTS   AGE
    stress-8554657b94-29x5n   1/1     Running   0          27s
    stress-8554657b94-2cfr6   1/1     Running   0          25s
    stress-8554657b94-46qjv   1/1     Running   0          26s
    stress-8554657b94-5x7rk   1/1     Running   0          26s
    stress-8554657b94-blx6g   1/1     Running   0          25s
    stress-8554657b94-bw4gw   1/1     Running   0          26s
    stress-8554657b94-ckfqc   1/1     Running   0          25s
    stress-8554657b94-crz2n   1/1     Running   0          25s
    stress-8554657b94-dtdhm   1/1     Running   0          27s
    stress-8554657b94-jthpm   1/1     Running   0          27s
    stress-8554657b94-kgvnx   1/1     Running   0          25s
    stress-8554657b94-l4xs7   1/1     Running   0          26s
    stress-8554657b94-ld9tj   1/1     Running   0          26s
    stress-8554657b94-m2nzl   1/1     Running   0          25s
    stress-8554657b94-mgzqn   1/1     Running   0          26s
    stress-8554657b94-p8d7v   1/1     Running   0          25s
    stress-8554657b94-r6wcr   1/1     Running   0          27s
    stress-8554657b94-rb6n7   1/1     Running   0          25s
    stress-8554657b94-tczpj   1/1     Running   0          25s
    stress-8554657b94-tdzwm   1/1     Running   0          26s
    stress-8554657b94-xnmjf   1/1     Running   0          28s
    stress-8554657b94-xnp9c   1/1     Running   0          26s
    stress-8554657b94-xr9st   1/1     Running   0          27s
    stress-8554657b94-z89sq   1/1     Running   0          25s
    stress-8554657b94-ztvjk   1/1     Running   0          27s
    ```
- Once the `stress` Pods are running (one per core outside cyclictests or reserved cres as per previous example). Proceed to run the `cyclictest` Pod which will run for 10 minutes:
    ```
    $ oc create -f 08-rt-test-cyclictest.yaml
    pod/cyclictest created
    $ oc get pods cyclictest
    NAME         READY   STATUS    RESTARTS   AGE
    cyclictest   1/1     Running   0          19s
    ```

- After 10 minutes validate the container is in `Completed` state.
    ```
    $ oc get pods cyclictest
    NAME         READY   STATUS      RESTARTS   AGE
    cyclictest   0/1     Completed   0          11m
    ```

- The results will be under `/tmp/cyclictest/cyclictest_10m.out` in the corresponding worker node.
    ```
    $ oc debug node/worker-3.ocp4poc.lab.shift.zone
    Starting pod/worker-3ocp4poclabshiftzone-debug ...
    To use host binaries, run `chroot /host`
    Pod IP: 198.18.100.18
    If you don't see a command prompt, try pressing enter.
    sh-4.2# chroot /host
    sh-4.4# grep Latencies /tmp/cyclictest/cyclictest_10m.out
    # Min Latencies: 00003 00003 00003 00003
    # Avg Latencies: 00004 00003 00003 00003
    # Max Latencies: 00084 00084 00084 00086
    sh-4.4#
    ```

- For longer runtime, for example to setup a test to run for 1 hour modify the environment variable of the cyclictest Pod:
    ```
    env:
      - name: DURATION
        value: "1h"
    ```
    After running, the output for this test will be `/tmp/cyclictest/cyclictest_1h.out`
    ```
    sh-4.4# grep Latencies /tmp/cyclictest/cyclictest_1h.out
    # Min Latencies: 00003 00003 00003 00003
    # Avg Latencies: 00004 00003 00003 00003
    # Max Latencies: 000XX 000XX 000XX 000XX
    ```

# Acknowledgements

Thanks to the help from [Colin Walters](https://github.com/cgwalters) and [Yolanda Robla Mota](https://github.com/yrobla)