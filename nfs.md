<!-- -->
# Starting Up an NFS Service for Other Linux Devices

Usually your home directory on your Linux desktop is where most of your
important files reside.  When you shutdown your desktop then those files are 
inaccessible.  If you also have a Linux laptop then it would be nice to
have the same home directory available on both the desktop and the laptop.

Putting your home directory on the Linux server would solve this issue.
Here we look at installing an NFS service for 24x7 availability.

## Configure the NFS Daemons

First install the needed packages.  The *nfs-common* package contains both
client and server elements; the *nfs-kernel-server* contains the server 
daemons *rpc.mountd* and *rpc.nfsd*.

~~~~ {.shell}
$ sudo apt install nfs-common nfs-kernel-server
...
The following NEW packages will be installed:
  keyutils libevent-core-2.1-7 nfs-common nfs-kernel-server rpcbind
...
Setting up rpcbind (1.2.6-2build1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/rpcbind.service ...
Created symlink /etc/systemd/system/sockets.target.wants/rpcbind.socket ...
...
Creating config file /etc/idmapd.conf with new version
Creating config file /etc/nfs.conf with new version
...
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-client.target ...
Created symlink /etc/systemd/system/remote-fs.target.wants/nfs-client.target ...
...
Setting up nfs-kernel-server (1:2.6.1-1ubuntu1.2) ...
Created symlink /etc/systemd/system/nfs-client.target.wants/nfs-blkmap.service ...
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service ...
...
Creating config file /etc/exports with new version
Creating config file /etc/default/nfs-kernel-server with new version
...

// show NFS and RPC services which are now enabled:
$ systemctl list-unit-files --state=enabled | egrep 'nfs|rpc'
nfs-blkmap.service                  enabled enabled
nfs-server.service                  enabled enabled
rpcbind.service                     enabled enabled
rpcbind.socket                      enabled enabled
nfs-client.target                   enabled enabled

// show NFS and RPC processes currently running:
$ ps -ef |egrep 'nfs|rpc'
\_rpc      271754       1  0 10:45 ?        00:00:00 /sbin/rpcbind -f -w
root      272176       2  0 10:46 ?        00:00:00 [rpciod]
root      272280       1  0 10:46 ?        00:00:00 /usr/sbin/rpc.idmapd
statd     272282       1  0 10:46 ?        00:00:00 /sbin/rpc.statd
root      272285       1  0 10:46 ?        00:00:00 /usr/sbin/nfsdcld
root      272286       1  0 10:46 ?        00:00:00 /usr/sbin/rpc.mountd
root      272294       2  0 10:46 ?        00:00:00 [nfsd]
root      272295       2  0 10:46 ?        00:00:00 [nfsd]
root      272296       2  0 10:46 ?        00:00:00 [nfsd]
root      272297       2  0 10:46 ?        00:00:00 [nfsd]
root      272298       2  0 10:46 ?        00:00:00 [nfsd]
root      272299       2  0 10:46 ?        00:00:00 [nfsd]
root      272300       2  0 10:46 ?        00:00:00 [nfsd]
root      272301       2  0 10:46 ?        00:00:00 [nfsd]
~~~~

There are a few files to configure.  We remove IPv6 RPC services by commenting
out *udp6* and *tcp6* from /etc/netconfig:

~~~~ {.shell}
$ sudo cp -p /etc/netconfig /etc/netconfig.orig
$ sudo nano /etc/netconfig
$ diff /etc/netconfig.orig /etc/netconfig
15,16c15,16
< udp6       tpi_clts      v     inet6    udp     -       -
< tcp6       tpi_cots_ord  v     inet6    tcp     -       -
---
> #udp6       tpi_clts      v     inet6    udp     -       -
> #tcp6       tpi_cots_ord  v     inet6    tcp     -       -
~~~~

Before restarting the daemons we see various IPv6 processes running:

~~~~ {.shell}
$ sudo lsof -i | grep rpc | grep IPv6
systemd        1      root  144u  IPv6 899098    0t0  TCP :sunrpc (LISTEN)
systemd        1      root  145u  IPv6 899100    0t0  UDP :sunrpc 
rpcbind   271754      \_rpc    6u  IPv6 899098    0t0  TCP :sunrpc (LISTEN)
rpcbind   271754      \_rpc    7u  IPv6 899100    0t0  UDP :sunrpc 
rpc.statd 272282     statd   10u  IPv6 897604    0t0  UDP :59540 
rpc.statd 272282     statd   11u  IPv6 897608    0t0  TCP :47971 (LISTEN)
rpc.mount 272286      root    6u  IPv6 900420    0t0  UDP :53821 
rpc.mount 272286      root    7u  IPv6 902332    0t0  TCP :45067 (LISTEN)
rpc.mount 272286      root   10u  IPv6 902347    0t0  UDP :43059 
rpc.mount 272286      root   11u  IPv6 902352    0t0  TCP :39207 (LISTEN)
rpc.mount 272286      root   14u  IPv6 902367    0t0  UDP :52374 
rpc.mount 272286      root   15u  IPv6 902372    0t0  TCP :52705 (LISTEN)

// restart the daemons (only the rpcbind ports still report IPv6)
$ sudo systemctl restart rpcbind nfs-server rpc-statd

~~~~

Finally, the NFS shares need to be published and shared.  It is best to
export */home* so that logins on both the server and any clients use the
same '/home' directories.  If you use other directory names you need to 
change the home directory path in the password file, or create a symbolic
link from */home* to the new directory -- though we can do this, it is
a bit messy.

~~~~ {.shell}
// Edit the exports file on the NFS server:
$ sudo cp -p /etc/exports /etc/exports.orig
$ sudo nano /etc/exports

$ diff /etc/exports.orig /etc/exports
6c6,11
< #
---
> 
> # Export home directories using NFSv3 syntax
> # Limit nfs access to the IP address of the client node(s)
> /home   192.168.1.65(rw,sync,no_subtree_check) \
>         192.168.1.85(rw,sync,no_subtree_check)
>
~~~~

Then export the share.  It can then be mounted on other clients.

~~~~ {.shell}
$ sudo exportfs -a
~~~~

## Configure NFS Clients on Other Hosts

We will use *autofs* on other Linux hosts to automatically mount and
unmount the home directory on demand.  Note that any current directories
in /home on your client will be affected, since we are going to mount the
server's /home directory using the /home directory.  Anything in that
directory will be hidden until you unmount the server's version of /home.
Consider migrating the content of /home to the server.

This example uses another Ubuntu host as the NFS client.  We install autofs
on it and then edit the automount map files as needed.

~~~~ {.shell}
// install the autofs package
$ sudo apt install autofs
The following additional packages will be installed:
  keyutils libevent-core-2.1-7 nfs-common rpcbind
...
Setting up rpcbind (1.2.6-2build1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/rpcbind.service ...
Created symlink /etc/systemd/system/sockets.target.wants/rpcbind.socket ...
...
Setting up autofs (5.1.8-1ubuntu1.2) ...
Creating config file /etc/auto.master with new version
...
Setting up nfs-common (1:2.6.1-1ubuntu1.2) ...
...
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-client.target ...
Created symlink /etc/systemd/system/remote-fs.target.wants/nfs-client.target ...

// If you are getting used to reading 'man' pages, then it is useful to use
// the 'man -k' option to get a list and description of all man pages available
// matching a topic:
$ man -k autofs
auto.master (5)      - Master Map for automounter consulted by autofs
autofs (5)           - Format of the automounter maps
autofs (8)           - Service control for the automounter
autofs.conf (5)      - autofs configuration
automount (8)        - manage autofs mount points

// Now edit configuration file /etc/autofs.conf and get rid of the 'amd' section
// Keep things simple.
$ cd /etc
$ sudo cp -p autofs.conf autofs.conf.orig
$ sudo nano autofs.conf
$ diff autofs.conf.orig autofs.conf
404c404
< [ amd ]
---
> #[ amd ]
410c410
< dismount_interval = 300
---
> #dismount_interval = 300

// Edit configuration file /etc/auto.master
// We comment out the '+auto.master' line and append the auto.home configuration

$ sudo cp -p auto.master auto.master.orig
$ sudo nano auto.master
$ diff auto.master.orig auto.master
22c22
< +dir:/etc/auto.master.d
---
> #+dir:/etc/auto.master.d
38c38,43
< +auto.master
---
> #+auto.master
> 
> ## This is a direct mountpoint for NFS-provided home directories ..
> /-      /etc/auto.home --timeout 300
> 

// We create /etc/auto.home
$ sudo nano /etc/auto.home
$ cat /etc/auto.home
## Every regular user you create needs an entry in this file
##
/home/myname \
  -rw,hard,intr,rsize=32768,wsize=32768,retrans=2,timeo=600,tcp,nfsvers=3 \
  192.168.1.90:/home/myname
~~~~

Now, you would normally restart autofs - but do not do this immediately:

~~~~ {.shell}
// restart autofs:
$ sudo systemctl restart autofs
~~~~

Consider your impending 'chicken-and-egg' issue regarding being a regular
user logged into your home directory while you restart autofs, causing
your current home directory to disappear.  There is some
[help on this topic in the appendix](#root).  Perhaps the easiest solution
if you do not want to fiddle with changes to root access is to
**reboot your client device**.  Then when the client is back up again you
should now have a home directory that is served by your server.

~~~~ {.shell}
$ pwd
/home/myname
$ df -h .
Filesystem                    Size  Used Avail Use% Mounted on
192.168.1.90:/home/myname      50G  464M   50G   1% /home/myname
~~~~

