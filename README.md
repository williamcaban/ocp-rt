# OCP 4.3: Enabling real-time worker (RHCOS-RT)

```
####################################################
# NOTE: WORK IN PROGRESS. UNSUPPORTED PROCEDURE.
####################################################
```

## Setup local web server as RPM and script repos

**NOTE:** Instructions assuming `rhel-8.1-x86_64-dvd-rt.iso` is the ISO image of the RHEL DVD with the RT repos.

- Setup local repo from RHEL-RT 8.1 DVD
    ```
    mkdir /tmp/RHEL-8.1-RT
    mount -o loop,ro /root/rhel-8.1-x86_64-dvd-rt.iso /tmp/RHEL-8.1-RT 

    mkdir -pv /opt/nginx/html/RHEL-8.1-RT
    cp -afZ /tmp/RHEL-8.1-RT/. /opt/nginx/html/RHEL-8.1-RT/
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/RHEL-8.1-RT/

    umount /tmp/RHEL-8.1-RT
    ````
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

- Create MachineConfigPool (MCP) for `worker-rt` and the Tuned profiles:
    ```
    oc create -f 00-mcp-worker-rt.yaml
    oc create -f 00-tuned-network-latency.yaml
    oc create -f 01-tuned-rt.yaml
    ```

- Assign the `worker-rt` label to the MCP

    **NOTE:** *Due to a bug, for now we need to label the `worker` MCP to receive the KubeletConfig so that `worker-rt` can have it. Once the bug is fixed only the `worker-rt` MCP should be labeled.*
    ```
    oc label machineconfigpool worker worker-rt=""
    ```

- Create the MachineConfig with the `kernelArguments` for the real-time Nodes. Create `KubeletConfigs` to setup kubelet parameters optimized for the real-time workload
    ```
    oc create -f 05-mc-kargs-worker-rt.yaml
    oc create -f 05-kubeletconfig-worker-rt.yaml
    ```

- Label the Node to use the new MCP to apply the RT role
    ```
    oc label node <node_name> node-role.kubernetes.io/worker-rt=""
    ```
- After the MCP is applied the node will reboot

## RHCOS-RT Validations

- Validate the desired worker node has the desired worker-rt role:
    ```
    # oc get nodes
    NAME                          STATUS   ROLES              AGE   VERSION
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

# Tests with Demo RT workload

Sample setup for worker-rt node with 16 cores:
- 1c for kubelet
- 2c for system
- 4c for cyclictest
- 9c for stress-ng

***Note on `isolcpus`:*** The `isolcpus` Kernel parameter is good if every workload on the worker is defined using guaranteed class. Otherwise, everything goes to the non-isolated cores and the performance drop. For this reason, these tests do not use `isolcpus` and instead rely on CPU Manager for the proper behavior. For this it uses the Kubelet flags `kubeReserved`  and `systemReserved`.


- Create demo project and prepare to run the `cyclictest`:
    ```
    oc new-project demo-rt

    oc adm policy add-scc-to-user privileged -z default

    oc create -f 07-rt-stress-ng.yaml

    # oc get pods
    NAME                      READY   STATUS    RESTARTS   AGE
    stress-8554657b94-2qk4j   1/1     Running     0          25s
    stress-8554657b94-6bmjb   1/1     Running     0          25s
    stress-8554657b94-6k6zh   1/1     Running     0          25s
    stress-8554657b94-6qzdt   1/1     Running     0          25s
    stress-8554657b94-bzp6n   1/1     Running     0          25s
    stress-8554657b94-crzvd   1/1     Running     0          25s
    stress-8554657b94-fkv5z   1/1     Running     0          25s
    stress-8554657b94-j5mwb   1/1     Running     0          25s
    stress-8554657b94-s9x4j   1/1     Running     0          25s
    ```

- Once the `stress` Pods are running (one per core outside cyclictests or reserved cores, as per previous example). Proceed to run the `cyclictest` Pod which will run for 10 minutes:
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

    Example with Hyperthreading enabled:
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
    Example with Hyperthreading disabled shows a ~9us improvement:
    ```
    # Min Latencies: 00003 00003 00003 00003
    # Avg Latencies: 00003 00003 00003 00003
    # Max Latencies: 00077 00078 00082 00077
    ```

    ```NOTE: We are still investigating the Max latency results as seems to be due to the testing methodology.```

- For tests with longer runtime, modify the environment variable `DURATION` in the cyclictest `Pod` definition:
  
    Setup to run `cyclictest` for 12 hours
    ```
    env:
      - name: DURATION
        value: "12h"
    ```
    After running for the specified amount of time, the output for the test will be at `/tmp/cyclictest/cyclictest_12h.out` in the Node that executed it:
    ```
    sh-4.4# grep Latencies /tmp/cyclictest/cyclictest_12h.out
    # Min Latencies: 00002 00002 00002 00002
    # Avg Latencies: 00002 00002 00003 00002
    ...
    ```

## Swap in an updated RT kernel

If you've already applied an override to use the RT kernel, and you want to test a *different* RT kernel, starting from a situation like this where I've downloaded build `-154`, and want to switch to `-155`:

```
[root@coreos ~]# rpm-ostree status -b
State: idle
AutomaticUpdates: disabled
BootedDeployment:
* ostree://6c766806a9edd0023f230cccd14f4f2fe4fdd0149fb64b14ed8c6552397f098f
                   Version: 43.81.201911262047.0 (2019-11-26T20:49:55Z)
       RemovedBasePackages: kernel-core kernel-modules kernel kernel-modules-extra 4.18.0-147.0.3.el8_1
      ReplacedBasePackages: microcode_ctl 4:20190618-1.20191112.1.el8_1 -> 4:20190918-3.rhcos.1.el8
             LocalPackages: kernel-rt-core-4.18.0-154.rt13.11.el8.x86_64 kernel-rt-modules-extra-4.18.0-154.rt13.11.el8.x86_64 kernel-rt-modules-4.18.0-154.rt13.11.el8.x86_64
[root@coreos ~]# ll
total 107952
-rw-r--r--. 1 root root 27130748 Nov 27 15:49 kernel-rt-core-4.18.0-154.rt13.11.el8.x86_64.rpm
-rw-r--r--. 1 root root 27255152 Nov 27 16:01 kernel-rt-core-4.18.0-155.rt13.12.el8.x86_64.rpm
-rw-r--r--. 1 root root 23889456 Nov 27 15:49 kernel-rt-modules-4.18.0-154.rt13.11.el8.x86_64.rpm
-rw-r--r--. 1 root root 23937384 Nov 27 16:01 kernel-rt-modules-4.18.0-155.rt13.12.el8.x86_64.rpm
-rw-r--r--. 1 root root  3063840 Nov 27 15:49 kernel-rt-modules-extra-4.18.0-154.rt13.11.el8.x86_64.rpm
-rw-r--r--. 1 root root  3113340 Nov 27 16:01 kernel-rt-modules-extra-4.18.0-155.rt13.12.el8.x86_64.rpm
-rw-r--r--. 1 root root  2130352 Nov 27 15:54 microcode_ctl-20190918-3.rhcos.1.el8.x86_64.rpm
[root@coreos ~]# rpm-ostree uninstall kernel-rt-{core,modules,modules-extra} --install kernel-rt-core-4.18.0-155.rt13.12.el8.x86_64.rpm --install kernel-rt-modules-4.18.0-155.rt13.12.el8.x86_64.rpm  --install kernel-rt-modules-extra-4.18.0-155.rt13.12.el8.x86_64.rpm 
```

Note here we're telling rpm-ostree to uninstall the previous overlay packages, then follow a similar command line invocation to switch to `-155` all as part of one transaction.

# Acknowledgements

Thanks to the help from [Colin Walters](https://github.com/cgwalters) and [Yolanda Robla Mota](https://github.com/yrobla)
