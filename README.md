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


