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
    slogin core@worker-3

    [core@worker-3 ~]$ sudo -i

    [root@worker-3 ~]# curl -s http://198.18.100.1:8000/rhcos-rt.sh | bash

    [root@worker-3 ~]# rpm-ostree status
    State: idle
    AutomaticUpdates: disabled
    Deployments:
    ● pivot://registry.svc.ci.openshift.org/ocp/4.3-2019-11-05-194939@sha256:3467568ce4f4cc41f29c1e1eef8c72ed188f940d923e0cb94b705d1599af3123
                CustomOrigin: Managed by machine-config-operator
                    Version: 43.81.201911051743.0 (2019-11-05T17:48:00Z)
        RemovedBasePackages: kernel-core kernel-modules kernel kernel-modules-extra 4.18.0-147.el8
        ReplacedBasePackages: microcode_ctl 4:20190618-1.20190918.2.el8_1 -> 4:20190918-3.rhcos.1.el8
            LayeredPackages: kernel-rt-core kernel-rt-modules kernel-rt-modules-extra

    [root@worker-3 ~]# systemctl reboot
    ```

## Prepare OpenShift for RT worker nodes

- Create OCP MCP, Tuned Profiles and MachineConfigs
    ```
    oc create -f 00-mcp-worker-rt.yaml
    oc create -f 00-tuned-network-latency.yaml
    oc create -f 01-tuned-rt.yaml
    oc create -f 05-mc-rt.yaml
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
[core@worker-3 ~]$ cat /proc/cmdline
BOOT_IMAGE=/ostree/rhcos-02a1645a0b585894d46cfa6462693de7e97d59dbdb14383663019a2f301a62f3/vmlinuz-4.18.0-147.rt24.93.el8.x86_64 console=tty0 console=ttyS0,115200n8 rootflags=defaults,prjquota rw root=UUID=6101ba79-239a-439e-b891-6315c6c4b7bd ostree=/ostree/boot.1/rhcos/02a1645a0b585894d46cfa6462693de7e97d59dbdb14383663019a2f301a62f3/0 coreos.oem.id=metal ignition.platform.id=metal default_hugepagesz=1G hugepagesz=1G hugepages=32 isolcpus=2-24 nohz=on nohz_full=2-24 rcu_nocbs=2-24 nosoftlockup nmi_watchdog=0 audit=0 mce=off kthread_cpus=0 irqaffinity=0 skew_tick=1 processor.max_cstate=1 idle=poll intel_pstate=disable intel_idle.max_cstate=0 intel_iommu=on iommu=pt
[core@worker-3 ~]$
```

# Demo RT workload

```WORK IN PROGRESS```



# Acknowledgements

Thanks to the help from [Colin Walters](https://github.com/cgwalters) and [Yolanda Robla Mota](https://github.com/yrobla)