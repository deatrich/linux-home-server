<!-- -->
# Backing up your server

Always, always, do some kind of backups on your server.  For
system backups, very little actually needs to be backed up, yet it is
important to get into a frame of mind where you think about these things.
Let's look at what you should back up on your server, and how you might do it.

There is no need to back up everything - you can always reinstall and 
reconfigure.  This is my favourite list of system directories to back up:

  * /etc  -- a lot of system configuration is in this directory.  Some
             important configuration files found here are: the host's
             secure-shell keys, user account details, and most server
             configuration changes
  * /home    -- this is where your user account resides
  * /root    -- this is the superuser's home directory
  * /var/log -- system log files are here; for forensic reasons I back them up
  * /var/spool -- in case you have personalized cron job entries
  * /var/www -- if you have a web server then it's data files are usually here

If you are playing with database services then you need to inform yourself
which directories and/or data exports should be added and/or used for backups.
Note that when you have create a Samba or an NFS server you will have other
data directories to back up, and these directories might be large.

A [backup process and a link to an example backup script](#backups) are
in the appendix.  We look at backing up both system and data directories,
including the backup of large directories.  Compressed system directories
are typically small. But /home and /data/shared might be large.  Be aware
of your space needs, and adjust backups accordingly.

## Recovering files from backups

Recovering files from backups is fairly easy.  It is best to use an
empty directory with adequate space.  In this example we recover files from
compressed tar files.  We unpack the tar files *etc.tgz* and *home.tgz*
in the empty directory, and then move or copy any files into place in the
file system.  Example:

```shell
// This example unpacks home.tgz and etc.tgz.  Do this with sudo so that
// files are unpacked with the correct permissions.
$ sudo mkdir /var/local-recovery

// We can copy files from the local backup tree: /var/local-backups/
// or from the external drive once we mount it:  /mnt/backups/
// So use the needed pathname instead of '/path/to/' below:
$ sudo cp -ip /path/to/home.tgz /path/to/etc.tgz  /var/local-recovery/

$ cd /var/local-recovery
$ sudo tar -zxf etc.tgz
$ sudo tar -zxf home.tgz
$ sudo rm etc.tgz home.tgz
$ ls -l 
drwxr-xr-x 152 root root 12288 Jun  1 10:56 etc
drwxr-xr-x   3 root root  4096 May 25 10:45 home
$ ls -l home/
drwxr-x--- 25 myname myname 4096 Jun  1 21:12 myname
```

If you need to recover files from large directory backups then you can
copy the files directly from the removable media to your target directories.
For large directory backups we do not compress the backed up files, since
it takes some time and may introduce an additional disk space problem.

```shell
// This example recovers a directory inside the large directory backup of
// /home.  First mount the USB drive -- the example partition here is at
// /dev/sda1:
$ sudo mount /dev/sda1 /mnt
$ cd /mnt/rsyncs
$ ls
0  3  5  copy
$ cd 0/home/myname/
$ ls
bin  doc  downloads  etc  git  icons  inc  lib  src

// Since the files are my files then I do not need to use 'sudo'.
// Here I am recovering my 'bin' directory.
// Note that I copy it to a different directory name so that I have the
// option of comparing any existing 'bin' directory in my home.
$ cp -a bin ~/bin.recovered

// Change directories away from the USB drive so that you can unmount it.
// You cannot unmount a file system if you are parked in it:
$ cd 
$ sudo umount /mnt
$ pwd
/home/myname
$ diff -r bin bin.recovered
```

