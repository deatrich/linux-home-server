<!-- -->
# Setting up a virtualization service with QEMU/KVM

Running multiple hosts virtually from the same hardware is very convenient
and useful; you might want to:

  * experiment with other Linux distributions
  * experiment with other Operating Systems
  * test beta software
  * set up and test a new service without polluting your home server

Running other hosts virtually requires sufficient memory and diskspace.
Though my Linux server only has 4 GB of memory, I set up an example
Rocky Linux 8 virtual host to demonstrate the process.  Recall that this
server also runs Samba, remote desktops, NFS, Apache, Git and MySQL.  It
is much better to have 8 GB of memory to start with when implementing
virtualization.

Traditionally virtualization is deployed on x86 hardware (your *bog standard*
server room rack server) with Intel or AMD processors, so much of the
documentation is geared for those platforms.
Systems like the Raspberry Pi with a Broadcom-based SoC[^soc] and [ARM][arm]
processors are relatively new to hardware-based virtualization.

Though there are [many choices for virtualization software][virt-software],
here we use the combination of three integrated open source software projects
to build and manage running virtual hosts:

[QEMU][qemu]
: stands for *QuickEmulator*
: can fully emulate another hardware system, but is much slower without hardware
  acceleration

[libvirt][libvirt]
: is a multifaceted toolkit used for virtualization management

[KVM][kvm]
: stands for *Kernel-based Virtual Machine*
: is either a kernel module, or is built into the kernel
: the processor (CPU) must have hardware virtualization capabilities
  in order to support KVM

[^soc]: [System on a Chip][what-is-soc]

[what-is-soc]: https://www.techradar.com/news/computing/pc/system-on-a-chip-what-you-need-to-know-about-socs-1147235
[arm]: https://en.wikipedia.org/wiki/ARM_architecture_family
[virt-software]: https://www.fosslinux.com/48755/top-opensource-virtualization-software-for-linux.htm
[qemu]: https://github.com/qemu/qemu
[libvirt]: https://en.wikipedia.org/wiki/Libvirt
[kvm]: https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine

## Verifying kernel support

Before installing virtualization software packages we can check to be sure
that our kernel supports KVM:

```shell
// Install cpu-checker on the Raspberry Pi so that we can check for kvm
// capatibilty:
$ sudo apt install cpu-checker
...

$ kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used

// Compare this to the older Odroid, which is not compatible:
$ kvm-ok
INFO: Your CPU does not support KVM extensions
INFO: For more detailed results, you should run this as root
HINT:   sudo /usr/sbin/kvm-ok
$ sudo kvm-ok
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used

// Back on the Raspberry Pi, here are some other ways to look at kernel
// capabilities.  The currently running kernel has a configuration file
// in /boot which mentions all kernel options configurated:
$ grep CONFIG_KVM /boot/config-$(uname -r)
CONFIG_KVM=y
CONFIG_KVM_MMIO=y
CONFIG_KVM_VFIO=y
CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT=y
CONFIG_KVM_XFER_TO_GUEST_WORK=y

// As well, KVM support is often provided by a kernel module; you can use
// 'modinfo' to query about it. On a Pi it reports that it is 'built-in'
$ modinfo kvm
name:           kvm
filename:       (builtin)
license:        GPL
file:           arch/arm64/kvm/kvm
author:         Qumranet
parm:           halt_poll_ns:uint
parm:           halt_poll_ns_grow:uint
parm:           halt_poll_ns_grow_start:uint
parm:           halt_poll_ns_shrink:uint

// Compare the output to an x86 Ubuntu virtual machine where KVM support is 
// provided by a kernel module:
$ modinfo kvm | head
filename:       /lib/modules/5.19.0-46-generic/kernel/arch/x86/kvm/kvm.ko
license:        GPL
author:         Qumranet
srcversion:     637F3CEEFA045C6DB95F67D
depends:        
retpoline:      Y
intree:         Y
name:           kvm
vermagic:       5.19.0-46-generic SMP preempt mod_unload modversions 
...
```

## Changing the network interface to bridging mode

Before we go further, it is really useful to configure *bridge networking*.
If the host server has a bridging network configuration then any virtual
hosts which you install can connect directly to your LAN, and they appear as
independent hosts.  Otherwise the virtual hosts hide behind the Linux
host server's *NAT*[^nat] which will forward their traffic to the intended
destinations.  Other computers on your LAN will not be able to connect to
the virtual hosts unless you play with options like port forwarding on the
Linux server.

Setting up a bridge is not difficult.  Once you do it your server can keep
this configuration even if you eventually do not use virtualization services.
It is however important to have direct login access to your server in case you 
make any mistakes and lose your network connection.

Here are the commands which create an ethernet bridge:

```shell
// Show network connection names and become root
$ nmcli con show --active
NAME                UUID                                  TYPE      DEVICE 
ethernet-eth0       bc6badb3-3dde-4009-998d-2dee20831670  ethernet  eth0
$ sudo /bin/bash

// Let's copy the network manager configurations to another place
// If we have problems we can revert back to the previous configuration
# cp -a /etc/NetworkManager /var/tmp/NetworkManager.beforebridge

// We add the bridge interface and give it the name 'br0'
// By default the system names this connection 'bridge-br0' unless you pick
// a different name:
# nmcli con add type bridge ifname br0
Connection 'bridge-br0' (f1e8c688-5b47-4576-ad72-b0e082e34da1) successfully added.

// Assign the ethernet interface to this bridge by modifying the existing
// ethernet connection named ethernet-eth0:
# nmcli con modify ethernet-eth0 master bridge-br0 slave-type bridge
# nmcli con show --active
NAME           UUID                                  TYPE      DEVICE 
bridge-br0     f1e8c688-5b47-4576-ad72-b0e082e34da1  bridge    br0    
ethernet-eth0  bc6badb3-3dde-4009-998d-2dee20831670  ethernet  eth0   

// We want the bridge to have the same MAC address as the ethernet device,
// especially if you decide to stay with DHCP IP address assignment:
# nmcli con mod bridge-br0 ethernet.cloned-mac-address e4:5f:01:a7:22:55

// Let's turn off the Spanning Tree Protocol; we don't need it for our
// simple setup:
# nmcli con modify bridge-br0 bridge.stp no

// By default the bridge will ask for an IP address from your home router.
// Because I assign the network address information myself, then I set
// the IPv4 address, subnet mask, gateway and DNS statically to the bridge.
// Ignore this step if you will use DHCP instead.
# nmcli con modify bridge-br0 ipv4.method manual ipv4.addresses 192.168.1.90/24 gw4 192.168.1.254
# nmcli con modify bridge-br0 ipv4.dns "1.1.1.1 8.8.8.8 192.168.1.254 75.153.171.67"

// Bring the bridge up; it will take some seconds:
# nmcli con up bridge-br0
Connection successfully activated (master waiting for slaves) ...

# nmcli con show --active
NAME           UUID                                  TYPE      DEVICE 
bridge-br0     f1e8c688-5b47-4576-ad72-b0e082e34da1  bridge    br0    
ethernet-eth0  bc6badb3-3dde-4009-998d-2dee20831670  ethernet  eth0   
```

If you want to use a bridge-specific utility, you can install *bridge-utils*
so that you have access to the *brctl* command:

```shell
$ sudo apt install bridge-utils
...
$ brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.e45f01a7110d       no              eth0
```

[virt-network]: https://wiki.libvirt.org/Networking.html
[^nat]: Network Address Translation, used to hide internal device IP addresses
from external devices 

## Installing the software

Now we are ready to install the required software.  First we install
*qemu-system-arm*.  You could also install *qemu-kvm*, a virtual package, and
it will pick the right package to match your architecture, which is
qemu-system-arm:

```shell
$ sudo apt install qemu-system-arm
...
The following additional packages will be installed:
  ipxe-qemu ipxe-qemu-256k-compat-efi-roms libaio1 libcacard0 libiscsi7 libpmemobj1 librbd1 libslirp0 libspice-server1 libusbredirparser1 libvirglrenderer1
  qemu-block-extra qemu-efi-aarch64 qemu-efi-arm qemu-system-common qemu-system-data qemu-system-gui qemu-utils
...
Created symlink /etc/systemd/system/multi-user.target.wants/qemu-kvm.service ...
```

Then we install the needed libvirt packages:

```shell
$ sudo apt install libvirt-daemon-system libvirt-clients
...
The following additional packages will be installed:
  dmeventd jq libdevmapper-event1.02.1 libjq1 liblvm2cmd2.03 libnss-mymachines
  libonig5 libtpms0 libvirt-clients libvirt-daemon-config-network
  libvirt-daemon-config-nwfilter libvirt-daemon-driver-qemu
  libvirt-daemon-system-systemd libvirt0 libxml2-utils lvm2 mdevctl swtpm
  swtpm-tools systemd-container thin-provisioning-tools
...
Created symlink /etc/systemd/system/multi-user.target.wants/machines.target ...
...
Enabling libvirt default network
Created symlink /etc/systemd/system/multi-user.target.wants/libvirtd.service ...
...
Created symlink /etc/systemd/system/multi-user.target.wants/libvirt-guests.service ...
...
Created symlink /etc/systemd/system/sysinit.target.wants/blk-availability.service ...
Created symlink /etc/systemd/system/sysinit.target.wants/lvm2-monitor.service ...
...
Processing triggers for initramfs-tools (0.140ubuntu13.1) ...
update-initramfs: Generating /boot/initrd.img-5.15.0-1033-raspi
... (a bunch of messages occur whenever update-initramfs is invoked)
```

We also want *virt-manager*, a useful management GUI.  It will bring in 
virt-viewer and the *virtinst* package, which provides *virt-install*.

```shell
$ sudo apt install virt-manager
```

Note that we can install *qemu-system-x86*, which allows full system emulation
of binaries on x86 hardware; that is, i386 and x86_64.  However there is no
hardware acceleration for those architectures on a Raspberry Pi, so it is
too slow to use in any practical way.

## Disabling the default virtual network

```shell
// We will not be using the default virtual network, which operates behind
// a NAT.  Here we show what it is, and then we disable it:

$ virsh net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

$ virsh net-dumpxml default
<network>
  <name>default</name>
  <uuid>0e5a34e6-85c9-49ba-a38a-7ce4dfe49a34</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:05:29:43'/>
  <ip address='192.168.123.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
    </dhcp>
  </ip>
</network>

$ sudo /bin/bash
# virsh net-autostart default --disable
# virsh net-destroy default
# virsh net-undefine default
Network default has been undefined
# virsh net-list --all
 Name   State   Autostart   Persistent
----------------------------------------

```

## Setting up a disk area for clients and boot images

The default location for virtual hosts' disks and boot images in in:

*/var/lib/libvirt/boot*
: for boot images

*/var/lib/libvirt/images*
: for virtual host disk images

The disk space used can be very large, so I prefer to use instead a large
data disk which is mounted as */data*, in the sub-directory */data/kvm/*.

```shell
$ df -h /data/
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p3  142G   26G  115G  19% /data

$ sudo /bin/bash
# mkdir -p /data/kvm/clients /data/kvm/boot-isos

// Create pool for virtual host client disk images
# virsh pool-define-as --name clients --type dir --target /data/kvm/clients
Pool clients defined

// Create pool for boot iso installer images
# virsh pool-define-as --name boot-isos --type dir --target /data/kvm/boot-isos
Pool boot-isos defined

# virsh pool-list --all
 Name        State      Autostart
---------------------------------
 clients     inactive   no
 boot-isos   inactive   no

# virsh pool-start clients
Pool clients started
# virsh pool-start boot-isos
Pool boot-isos started

# virsh pool-autostart boot-isos
Pool boot-isos marked as autostarted
# virsh pool-autostart clients
Pool clients marked as autostarted

# virsh pool-list --all
 Name        State    Autostart
---------------------------------
 boot-isos   active   yes
 clients     active   yes

// Then I assign ownership to the boot images to myself:
$ sudo chown myname:myname /data/kvm/boot-images
$ scp -p desktop:/path/to/ubuntu-22.04.2-live-server-arm64.iso /data/kvm/boot-images/
$ scp -p desktop:/path/to/Rocky-8.8-aarch64-minimal.iso /data/kvm/boot-images/

# virsh vol-list boot-isos
 Name                                   Path
--------------------------------------------------------------------------------------------------
 Rocky-8.8-aarch64-minimal.iso          /data/kvm/boot-isos/Rocky-8.8-aarch64-minimal.iso
 ubuntu-22.04.2-live-server-arm64.iso   /data/kvm/boot-isos/ubuntu-22.04.2-live-server-arm64.iso

```

```shell
// change the disk pool path component to /data/kvm/clients below:
$ sudo virsh pool-edit default.xml

```

## Creating some virtual hosts

There are 2 ways to install virtual machines (VMs):

  * Using the *virt-manager* GUI
  * Using the *virt-install* command-line

As a demonstration I installed a couple of VMs -- one was an Ubuntu
22.04 minimal server, and the other was a Rocky 8.8 Linux minimal server.
Of course, both were ARM architectures so that the KVM acceleration capability
of the Raspberry Pi's architecture was used.

Note that all disk images for installed VMs are described by XML files, and
those XML files can always be found in */etc/libvirt/qemu/*.

### virt-manager

There are a number of [tutorials][virt-manager] on the web showing you how to
create a new VM using virt-manager, so I do not reproduce the process here.

Note that when you launch *virt-manager* it always takes some seconds to
appear.

Installing a minimal Ubuntu VM works with 1024 MB of RAM and a disk size
of 15 GB.  It is important in this case to select the 'minimized' base for
installation during the installation dialog.  You can also save time if you
avoid doing software updates during the installation.

It is very useful to always select 'Customize configuration before install'
on the last panel when creating a new VM.  Then you can look at the VM
details and change things before beginning the installation, such as:

  * change the virtual firmware selection in the overview
  * change the virtual network card (NIC) MAC address
  * add a boot menu in the boot options

[virt-manager]: https://phoenixnap.com/kb/ubuntu-install-kvm

### virt-install

The command-line utility *virt-install* is very useful.  It is best done
in a script because of the large number of options, but here is an example of 
using it to install Rocky Linux.

This Linux distribution needed more memory and disk space; I used about 1500 MB
of RAM and a disk size of 20 GB.

```shell
// This one had an issue falling into an EFI shell at installation startup.
// I fixed it with a ghastly set of options for the boot loader.  Trying the
// installation with virt-manager also required an unexpected option for
// the firmware option in order to get past the EFI shell.

// I set variables for the boot loader path and for the nvram path, so that
// the command below is less intimidating.  The man-page for virt-install 
// suggests trying this to see all the boot options:
//    virt-install --boot=?
# loader="/usr/share/AAVMF/AAVMF_CODE.fd"
# nvram="/usr/share/AAVMF/AAVMF_VARS.fd"
# virt-install --virt-type kvm --name rocky8 --arch aarch64 \
 --ram 1534 \
 --boot uefi \
 --boot loader=$loader,loader.readonly=yes,loader.type=pflash,nvram=$nvram \
 --cdrom /data/kvm/boot-isos/Rocky-8.8-aarch64-minimal.iso \
 --network bridge:br0,mac=52:54:00:FF:00:04 \
 --nographics \
 --accelerate \
 --disk path=/data/kvm/clients/rocky8.2.qcow2,size=20
```

<!--
```shell
```
 -->
