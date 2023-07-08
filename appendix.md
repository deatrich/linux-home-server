# Appendix {#appendix}

## Identifying Device Names for Storage Devices {#find-device}

In a Linux system it is important to correctly identify storage devices,
especially when you want to repartition or reformat them.  If you pick
the wrong device you might wipe out its data.

Start with *lsblk* to list all current block (storage) devices.  Note
that a microSD card in a microSD slot will be identified with a name
starting with */dev/mmcblk*.  But if you insert the microSD card into
a multi-slot USB-based card reader then the Linux kernel will identify any kind 
of inserted card in the reader as a generic 'scsi disk' type and it will
appear with a name which starts with */dev/sd*.

Here is an example of a Pi that has 3 storage disks and a USB card reader with
4 slots.  The lsblk command also shows active mountpoints.  The 3 disks are:

  * the Pi's system microSD card (mmcblk0) with 2 partitions mounted
      as */* and */boot/firmware*
  * a USB stick (sda) with 1 partition mounted as */usbdata*
  * a card reader with 4 slots -- 3 slots have 0 bytes, so they are
      empty (sdb, sdc, sdd) and one of the slots (sde) is occupied
      by another 256 GB microSD card which is listed with lesser size
      of 232 GB.
  * you can use *fdisk* and *parted* to look more closely at the sde device:

```shell
# lsblk -i 
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    1 238.5G  0 disk
`-sda1        8:1    1 238.5G  0 part /usbdata
sdb           8:16   1     0B  0 disk
sdc           8:32   1     0B  0 disk
sdd           8:48   1     0B  0 disk
sde           8:64   1 231.7G  0 disk
|-sde1        8:65   1   243M  0 part
`-sde2        8:66   1   5.9G  0 part
mmcblk0     179:0    0  59.4G  0 disk
|-mmcblk0p1 179:1    0   243M  0 part /boot/firmware
`-mmcblk0p2 179:2    0  59.2G  0 part /

# fdisk -l /dev/sde
Disk /dev/sde: 231.68 GiB, 248765218816 bytes, 485869568 sectors
Disk model: FCR-HS3       -3
...
Disklabel type: dos
Disk identifier: 0x11d94b9e

Device     Boot  Start      End  Sectors  Size Id Type
/dev/sde1  *      2048   499711   497664  243M  c W95 FAT32 (LBA)
/dev/sde2       499712 12969983 12470272  5.9G 83 Linux

# parted /dev/sde print
Model:  FCR-HS3 -3 (scsi)
Disk /dev/sde: 249GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  256MB   255MB   primary  fat16        boot, lba
 2      256MB   6641MB  6385MB  primary  ext4
```

You can pass options to the *lsblk* command so that you print out 
columns you are interested in -- try *lsblk \-\-help* to see other options.

```shell
# lsblk -i -o 'NAME,MODEL,VENDOR,SIZE,MOUNTPOINT,FSTYPE'
NAME        MODEL       VENDOR     SIZE MOUNTPOINT     FSTYPE
sda         Extreme Pro SanDisk  238.5G
`-sda1                           238.5G /usbdata       ext4
sdb         FCR-HS3 -0               0B
sdc         FCR-HS3 -1               0B
sdd         FCR-HS3 -2               0B
sde         FCR-HS3 -3           231.7G
|-sde1                             243M                vfat
`-sde2                             5.9G                ext4
mmcblk0                           59.4G
|-mmcblk0p1                        243M /boot/firmware vfat
`-mmcblk0p2                       59.2G /              ext4
```


## Installation Disk Creation from the Command-line {#image-cmds}

This is a generic approach to creating an installation image on removable
media; it generally works for various Linux distributions.

```shell
// create a directory for downloaded images
$ mkdir raspberry-pi-images
$ cd raspberry-pi-images

// Use wget to pull the compressed image into our directory
// (The web page also shows the file checksum so that you can verify
//  that the compressed file is not corrupted)
$ serverpath="https://releases.ubuntu-mate.org/jammy/arm64"
$ compressed="ubuntu-mate-22.04-desktop-arm64+raspi.img.xz"
$ wget -N -nd $serverpath"/"$compressed
$ sha256sum ubuntu-mate-22.04-desktop-arm64+raspi.img.xz
3b538f8462cdd957acfbab57f5d949faa607c50c3fb8e6e9d1ad13d5cd6c0c02 ...

// uncompress the file so we can write the image file to our microSD.
// the 1.9 GB compressed file uncompressed to 6.2 GB:
$ xz -dv ubuntu-mate-22.04-desktop-arm64+raspi.img.xz 
ubuntu-mate-22.04-desktop-arm64+raspi.img.xz (1/1)
 5.1 %      95.2 MiB / 404.4 MiB = 0.235    35 MiB/s     0:11   3 min 40 s
 ...
 100 %   1,847.8 MiB / 6,333.0 MiB = 0.292  27 MiB/s     3:50             
```

Now plug in the microSD card,
[identify the microSD card device name](#find-device), and then
use the *dd* command to write the image to it.  Safely remove the
device when you are done with the *eject* command.  In this example
the device name */dev/sdX* is not real; it is a place-holder for your
real device name:

```shell
$ img="ubuntu-mate-22.04-desktop-arm64+raspi.img"
$ sudo dd if=$img of=/dev/sdX bs=32M conv=fsync status=progress
$ sudo eject /dev/sdX
```

## Modify the Partitioning of the Installation Image {#mod-partition}

If you modify the microSD's partioning *before* you start the installation
then you can reserve a portion of the disk for
special data usage - for example as a shared Samba area or an NFS area.
We do this by expanding the main Linux partition up to 40 GB, and then we
create a third partition.

I show here how to do that from another Linux computer (in my case another Pi)
with a USB card reader and an inserted 256 GB microSD card.

There is a good graphical tool named *gparted* which is easy to use.
Beginners should certainly use it, and it is great when
managing a handful of servers (it is a different story if you are managing
dozens or thousands of servers).

Here are a few gparted notes:
  * You will need to first install it with *sudo apt install gparted*
  * If you opt for this tool then it is all you need
  * It is intuitive, and there are many [tutorials][gparted] on the web
  * Be careful to pick the correct disk from the drop-down list
  * Expand the second partition, then create the third (data) partition
  * Also use the tool to create an *ext4* file system on the third partition
    once you have created it
  * Once your new server is up and running you can further split your third
    partition into a fourth partition.  You only need to unmount the
    third partition temporarily and use gparted to create another partition,
    make a file system on it, and alter /etc/fstab.  I did this in order to
    move my home directory files to the fourth partition.

As always, I show the command-line example in this section. As a bonus
it shows a common problem of dealing with partition alignment when
manually editing partitions.  Skip the rest of this section if you
have opted for gparted.

Here are some common command-line tools to help us:

lsblk
: this command will list all block devices

fdisk
: this interactive text-based command can change disk partitioning
: To show all disk and their partitions, do:  fdisk -l
: You can only operate on one disk

parted
: this interactive text-based command can also change disk partitioning
: You can only operate on one disk

mkfs.ext4
: You should create an ext4 file system on the new partition

Here are some utilities used to find disk information:

  * *lshw -C disk*
  * *hdparm -I /dev/sdX*  (where X is a block device letter)
  * *smartctl -a /dev/sdX*  (needs *smartmontools* to be installed)

[gparted]: https://www.dedoimedo.com/computers/gparted.html#mozTocId133810

### Identify the Main Linux Partition on the microSD

First we need to [identify the device name](#find-device), and then we use that
device name in the partitioning tool.  In my test situation I am using
*/dev/sde* and I am targeting the main Linux (second) partition: */dev/sde2*.

### Expand the Main Linux Partition on the microSD

40 GB is lots of space for future system needs, so I decide to expand the
second partition from 6 up to 40 GB.

To be sure this partition is sound I run a check on it with *e2fsck*.
Then I use *parted* to expand the partition, and then *resize2fs* which can
adjusts the size of the underlying ext4 filesystem.

```shell
// run a filesystem check on the target partition:
$ sudo e2fsck /dev/sde2
e2fsck 1.46.5 (30-Dec-2021)
writable: clean, 224088/390144 files, 1485804/1558784 blocks

// invoke the partitioning tool *parted*, print the partition table
// for reference, and then resize the second partition:
$ sudo parted /dev/sde
...
(parted) print                                                            
...
Number  Start   End     Size    Type     File system  Flags
 1      1049kB  256MB   255MB   primary  fat16        boot, lba
 2      256MB   6641MB  6385MB  primary  ext4

(parted) resizepart
Partition number? 2                                                       
End?  [6641MB]? 40G                                                       

(parted) print                                                            
...
Number  Start   End     Size    Type     File system  Flags
 1      1049kB  256MB   255MB   primary  fat16        boot, lba
 2      256MB   40.0GB  39.7GB  primary  ext4

(parted) quit

// Now expand the underlying filesystem to the end of the partition
$ sudo resize2fs /dev/sde2
resize2fs 1.46.5 (30-Dec-2021)
Resizing the filesystem on /dev/sde2 to 9703161 (4k) blocks.
The filesystem on /dev/sde2 is now 9703161 (4k) blocks long.
```

### Create a New Data Partition

Now we want to create a third large partition.  We run into the problem
of partition alignment because I chose 40 GB for the second partition 
expansion without considering alignment for the next partition.

```shell
// invoke *parted* and print the partition table in sector units:
$ sudo parted /dev/sde
...
(parted) unit s print
Model:  FCR-HS3 -3 (scsi)
Disk /dev/sde: 485869568s
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start    End        Size       Type     File system  Flags
 1      2048s    499711s    497664s    primary  fat16        boot, lba
 2      499712s  78125000s  77625289s  primary  ext4

// the 'End' of the second partition is at 78125000 sectors, so I increment
// that number and try to create the third partition up to 100% of the disk
// There is a warning about partition alignment, so I cancel that operation
(parted) mkpart primary ext4 78125001 100%
Warning: The resulting partition is not properly aligned for best performance:
78125001s % 2048s != 0s
Ignore/Cancel? c
```

Disk technology has evolved considerably.  Block devices traditionally
had a default 512 byte sector size (a sector is the minimum usable unit),
but newer disks may have a 4096 (4k) sector size.
In order to work efficiently with
different sector sizes on various disk technologies a good starting point
is at sector 2048.  This is at 1 mebibyte (MiB), or 1048576 bytes into the
disk, since 512 bytes * 2048 sectors is 1048576 bytes.  You lose a bit of
disk space at the 'front' of the disk, but partitioning and file system 
data structures are better aligned, and disk performance is enhanced.

```shell
// To calculate the best starting sector number for an aligned new
//  partition simply calculate: 
//  TRUNCATE(FIRST_POSSIBLE_SECTOR / 2048) * 2048 + 2048
//  thus: 78125001 / 2048 = 38146.973144
//        TRUNCATE(38146.973144) = 38146
//        (38146 * 2048) + 2048  = 78125056

(parted) mkpart primary ext4 78125056 100%
(parted) print unit s 
...
Number  Start   End     Size    Type     File system  Flags
 1      1049kB  256MB   255MB   primary  fat16        boot, lba
 2      256MB   40.0GB  39.7GB  primary  ext4
 3      40.0GB  249GB   209GB   primary
(parted) align-check optimal 3                                            
3 aligned

(parted) unit s print free
...
Number  Start      End         Size        Type     File system  Flags
        32s        2047s       2016s                Free Space
 1      2048s      499711s     497664s     primary  fat16        boot, lba
 2      499712s    78125000s   77625289s   primary  ext4
        78125001s  78125055s   55s                  Free Space
 3      78125056s  485869567s  407744512s  primary

(parted) quit
```

Though we have now a bit of wasted space between partition 2 and 3, we can
extend partition 2 to use that space.  We need to resize its ext4 file system
after:

```shell
// first check the file system:
$ sudo e2fsck /dev/sde2
e2fsck 1.46.5 (30-Dec-2021)
writable: clean, 224088/2414016 files, 1615846/9703161 blocks

$ sudo parted /dev/sde
...
(parted) unit s print free
...
Number  Start      End         Size        Type     File system  Flags
        32s        2047s       2016s                Free Space
 1      2048s      499711s     497664s     primary  fat16        boot, lba
 2      499712s    78125000s   77625289s   primary  ext4
        78125001s  78125055s   55s                  Free Space
 3      78125056s  485869567s  407744512s  primary

(parted) resizepart
Partition number? 2                                                       
End?  [78125000s]? 78125055s                                              
(parted) print free
...
Number  Start      End         Size        Type     File system  Flags
        32s        2047s       2016s                Free Space
 1      2048s      499711s     497664s     primary  fat16        boot, lba
 2      499712s    78125055s   77625344s   primary  ext4
 3      78125056s  485869567s  407744512s  primary

(parted) quit                                                             
Information: You may need to update /etc/fstab.

$ sudo resize2fs /dev/sde2
resize2fs 1.46.5 (30-Dec-2021)
Resizing the filesystem on /dev/sde2 to 9703168 (4k) blocks.
The filesystem on /dev/sde2 is now 9703168 (4k) blocks long.
```

### Create a Filesystem on the New Data Partition

Ubuntu uses the *ext4* filesystem, so let's create that filesystem on the
new data partition:

```shell
$ sudo mkfs.ext4 /dev/sde3
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 50968064 4k blocks and 12746752 inodes
Filesystem UUID: 2dba1eef-34e4-47ed-90fc-c1938d5fa9e0
Superblock backups stored on blocks: 
    32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
    4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
```

By default, the generations of the [*ext* filesystems][ext] reserve 5% of the 
available space for the *root* user.  On a data partition where most
files created will belong to ordinary users this reservation is not necessary.
5% of 200 GB is 10 GB - that is a lot of space.  So it is a good idea
to reduce the percentage to 1%; do this with the *tune2fs* utility:

```shell
$ sudo tune2fs -l /dev/sde3 | grep -i count
...
Reserved block count:     2548403

$ sudo tune2fs -m 1 /dev/sde3
tune2fs 1.46.5 (30-Dec-2021)
Setting reserved blocks percentage to 1% (509680 blocks)

$ sudo tune2fs -l /dev/sde3 | grep -i count
...
Reserved block count:     509680
```

Lastly, let's add a *label* to this partition to make it easier to mount
the filesystem in the future.  We will use the label *PI-DATA*:

```shell
$ sudo tune2fs -L PI-DATA /dev/sde3
tune2fs 1.46.5 (30-Dec-2021)
```

[ext]: https://en.wikipedia.org/wiki/Extended_file_system

## Setting Up a Data Area {#data-area}

If you did not [modify the initial partitioning](#mod-partition) of your
microSD card then you will simply make a directory in the root of
your filesystem where we will store any data associated with a Samba
service or with an NFS service -- that is all.

In case you did make a data partition on the microSD card then
we *still* need to make a directory in the root of the filesystem
to mount that data partition: 

Let's call the directory */data*:

```shell
$ sudo mkdir /data
```

For the case with the third (data) partition then we need
to mount it and make the mount action permanent on reboots.  For this
we create an entry in the filesystem table, the */etc/fstab* file:

```shell
// make a backup copy first
$ sudo cp -p /etc/fstab /etc/fstab.orig

// There are 6 fields in an fstab entry:
//    1. the partition name, the partition label or the partition uuid
//    2. the directory to use for the mount point
//    3. the filesystem type
//    4. any mount options recognized by the mount command
//    5. use a zero here, it is a legacy option for the 'dump' command
//    6. the file system check ordering, use '2' here

// Edit the file, adding a mount entry line to the end of the file;
// recall that we added the label 'PI-DATA' to its filesystem:
$ sudo nano /etc/fstab
$ tail -2 /etc/fstab
LABEL=PI-DATA		/data           ext4	defaults  0  2

$ sudo mount /data
$ ls -la /data
total 24
drwxr-xr-x  3 root root  4096 Apr 16 10:35 .
drwxr-xr-x 20 root root  4096 Apr 16 14:30 ..
drwx------  2 root root 16384 Apr 16 10:35 lost+found

$ df -h /data
Filesystem      Size  Used Avail Use% Mounted on
/dev/sde3       191G   28K  189G   1% /data
```

## Some Command-line Utilities and Their Purpose {#eg-cmds}

-----------------------------------------------------------------------------
Command              Purpose
-------------------- --------------------------------------------------------
whoami               Shows your login name

id                   Shows your UID and GID numbers and all of your
                     group memberships

pwd                  Shows your current working directory

ls                   Shows a listing of your current directory

ls -l                Shows a detailed listing of your current directory

ls /                 Shows a listing of the base of the file system

ls /root             Try to show a listing of the superuser's home directory

sudo ls /root        Enter your password to show that listing

man sudo             Shows the manual page for the sudo command
                     (type q to quit)

date                 Shows the current date and time

cat /etc/lsb-release Shows the contents of this file

uptime               Shows how long this computer has been up

cd /tmp              Change directories to the 'tmp' directory

touch example        Creates a new (and empty) file named 'example'

rm -i example        Removes the file named 'example' if you respond with: y

mkdir thisdir        Creates a new directory named 'thisdir'

mkdir -\-help         Shows help on using the mkdir command

rmdir thisdir        Removes the directory named 'thisdir'

cd                   Without an argument, it takes you back to your home

file .bash\*         Shows what kind of files whose names start with '.bash'

echo $SHELL          Shows what shell you use

env | sort | less    Shows your environment variables, sorted (q to quit)
-----------------------------------------------------------------------------

The last example in the above list:

  env|sort|less

is actually 3 different commands *piped* together:
  - env  - output the environment variables in your shell
  - sort - sort the incoming text, by default alphabetically
  - less - show the output a page at a time

A pipe, represented by a vertical line, sends the output from one command
as the input for the next command.  It is a hallmark of the UNIX way of
doing things - create small programs that do one thing well, and string
the commands together to accomplish a larger task.

## A MATE Configuration Exercise {#mate-exercise}

Here are a series of exercises you can try on a fresh installation of the
MATE desktop.  By default, the initial mate configuration has 2 panels
(taskbars):

 - the top panel has:
   - a global menu button on the left
   - on the right is a group of icons that represent the state of things,
     known as 'Indicator Applet Complete' 

 - the bottom panel has:
   - on the left: a 'show desktop' button
   - on the left: a window list area, where current open windows as shown
   - on the right: a workspace area with 4 workspaces
   - on the right: a trash can button

You may like this setup; but here is a small exercise to give you a quick
start in making modifications.

### Modify the Top Panel

 1. Get rid of the bottom panel:
      - Right click on it and selecting 'Delete This Panel'.  We will add
        some of its contents to the top panel.
 2. On the top panel try a different menu presentation:
      - Right-click over the menu button on the top panel, and unlock its
        status.  Then right-click and select 'Remove from Panel'.
      - Now right-click and select 'Add to Panel'.  A list of applets mostly
        in alphabetical order will appear in a new window.  Select 
        'Classic Menu' (or the 'Compact Menu') and click on 'Add' and
        it will appear on the panel.
        Right-click on it and move it completely to the left.  Then
        right-click on it again and select 'Lock to Panel'.  Leave the
        'Add to Panel' window on your screen to continue adding applets.
 3. Add a couple of separators:
      - Scroll down to find 'Separator' and add it to the panel. Then
        right-click on it, move it against the menu, and lock it to the panel.
        (Locked items cannot be accidentally moved; it is a mystery why it
        does not always prevent deletion of some applet buttons...)
      - Add another separator, and move it about an inch to the right
        of the first separator and lock it.
 4. Add an active-window list:
      - Scroll down to find 'Window Selector' and add it to the panel to 
        the right of the second separator. It is a bit tricky to select
        it to lock it.  Right-click just to the right of the second separator
        line.  If you see 'System Monitor' at  the top of the menu list then
        lock it to the panel.  Right click on it again and select
        'Preferences'.  In the 'Window Grouping' options select
        'Group windows when space is limited' and then close that window.
 5. Add a workspace switcher:
      - scroll down to find 'Workspace Switcher' and add it to the panel. 
        Then right-click on it and select 'Preferences'.  Reduce the number
        of workspaces to 2, and name them - for example rename one to 'Home'
        and the other to 'Projects'.
      - Now right-click and move it as far right as you can, and lock it.
 6. Finally add a few of your own 'Launchers':
      - Add a firefox button:
         - right-click between the 2 separators and add to the panel:
           'Application Launcher'.  That will bring up a further selection.
           Click on Internet, then 'Firefox Web Browser' and add it.
           Again, right-click on the firefox button and move it to the left
           and lock it.
      - Add a terminal button:
         - right-click between the 2 separators and add to the panel:
           'MATE Terminal' and again move and lock it.

<!--
I add some custom application launchers related to the use of secure
shell as well.  If you are interested look at the secure shell example
further in the appendix.
-->

### Other Changes Done From the Control Center

 1. Find the Control Center in the System Menu.
 2. Under the 'Look and Feel' section select 'Screensaver':
      - Chanage the theme to something else, for example: 'Cosmos'.
      - Disable the 'lock screen' option if you wish.
 3. Under the 'Look and Feel' section select 'Windows':
      - Change the 'Titlebar Action' to 'Roll up'
 4. Under the 'Look and Feel' section select 'Appearance':
      - Try different themes
      - Try different backgrounds
 5. Under the 'Personal' section select 'Startup Applications':
      - Disable 'Blueman Applet' and 'Power Manager'
      - Select 'Show hidden' and look at what is lurking underneath,
        disable things that clearly are not important to you.

### Here are a Few Notes About Window Actions:

The 'Maximize Window' button (between the 'Minimize Window' button and
the 'Close Window' on the right of each window) has difference actions
depending on which mouse-click you use:

  - a right-mouse-button-click over the maximize button maximizes the window
    horizontally.  Another right-mouse-button-click will return it to the
    previous size.
  - a middle-mouse-button-click over the maximize button maximizes the window
    vertically.  Another middle-mouse-button-click will return it to the
    previous size.
  - a left-mouse-button-click over the maximize button maximizes the window
    completely.  Another left-mouse-button-click will return it to the
    previous size.


## An Example Process and Script for Backups {#backups}

There are many ways to do backups - this is just one example.  
An [example script][backup-script] in my github 'tools' area can do local
system backups; it can also do external backups to a removable drive,
such as an attached USB drive.  If you do only local backups without creating
a copy elsewhere then you run the risk of losing your data because of a
major failure (like losing or overwriting the local disk) when you don't
have another copy.

As well the script can handle large directories by using *rsync* to copy them 
them to a removable drive.  Though 'rsync' is typically used for remote copies
it can also be used locally.

The script also allows you to keep an additional copy of your large
directories on the removable drive.

The example script requires a few configuration entries into a file
named [*/etc/system-backup.conf*][backup-conf].  You need a designated local
directory; the files will be compressed so it requires only a few hundred
megabytes per day for each day of the week.  The provided example
script also keeps the last week of each month for one year.  If you use 
the external backup feature  and/or the large directory backup feature
then you simply need to provide the partition on the drive to use for
backups, as well as the mounted name of the directories where the files
will be copied.

In order to automate your backup script, you also need to create a *cronjob*
which will automatically run your script in the time slot you pick.  In
the example below you:

    * create the needed local directories specified in /etc/system-backup.conf
    * edit the configuration file if you choose different directory names
    * copy the configuration file and the script into place
    * run the script in test mode to check configuration correctness
    * create/edit the cronjob to run the local backup at 1 in the early morning

```shell
// Create local directory with permissions limiting access to
// backed-up files to users in the 'adm' group:
$ sudo mkdir /var/local-backups
$ sudo chown root:adm /var/local-backups
$ sudo mkdir /var/log/local-backups
$ sudo chown root:adm /var/local-backups

// Protect the backup directory by removing permissions for others:
$ sudo chmod o-rwx /var/local-backups

// Copy the configuration file to /etc/ and the shell script to /root/bin/
$ sudo cp /path/to/system-backup.conf /etc
$ sudo mkdir /root/bin
$ sudo cp /path/to/system-backup.sh /root/bin/
// The script must be marked as 'executable'; the chmod command will do that:
$ sudo chmod 755 /root/bin/system-backup.sh

// Edit the configuration file for the backups:
$ sudo nano /etc/system-backup.conf

// Run the script in debug mode from the command line to make sure
// that everything is correctly configured:
$ sudo /root/bin/system-backup.sh --test --local

// Create and edit the cronjob -- this example would run at 01:00 hrs
$ EDITOR=/bin/nano sudo crontab -e

// ( On Ubuntu 'crontab' puts cron-job files in /var/spool/cron/crontabs/ )
// Ask 'crontab' to list what that job is:
$ sudo crontab -l | tail -3

0 1 * * * /root/bin/system-backup.sh --local
```

If you will also synchronize backups to a USB drive, then you must make
directories at the root of the USB filesystem for backups.  The USB partition
name and the names of the directories must match the configuration file setup.
(example: your USB partition is /dev/sda1 and so you have set 'usbpartition'
in the configuration file to 'sda1')

```shell
// Here we also prepare for doing large directory rsyncs as well:
$ sudo mount /dev/sda1 /mnt
$ cd /mnt
$ sudo mkdir backups rsyncs
$ sudo mkdir rsyncs/copy

// Be sure to unmount the drive
$ cd
$ sudo umount /mnt

// Run the script in debug mode from the command line to make sure
// that everything is correctly configured for external copies of your
// local backups (that is, the ones in /var/local-backups/):
$ sudo /root/bin/system-backup.sh --test --external

// If you will also do large directory backups then test that option
// as well.  You must have set 'largedirs' in the configuration file:
$ sudo /root/bin/system-backup.sh --test --rsync-large

// Finally edit the cronjob and add the external backup options to the command:
$ EDITOR=/bin/nano sudo crontab -e
$ sudo crontab -l | tail -3

0 1 * * * /root/bin/system-backup.sh --local --external --rsync-large
```

In case your USB drive is formated for Windows then it should be okay
for all backups except for the large directories backup; that is,
with the option '--rsync-large'.

The script might issue some warnings about trying to preserve LINUX
permissions on the USB drive, but should otherwise work.  I need to verify
this case.  You may have to change the rsync arguments in the script from
*-aux* to *-rltux*.   I need to test the Windows-formatted usb drive opton.

If you ever need to restore files from your backups then you should unpack the
*tarballs* (compressed 'tar' files) on a Linux system and copy the needed
files into place on the filesystem.

[backup-script]: https://github.com/deatrich/tools/blob/main/system-backup.sh
[backup-conf]: https://github.com/deatrich/tools/blob/main/etc/system-backup.conf

## LAN (Local Area Network) Configuration files {#lan}

There are some common networking files that are interesting to configure
especially if you have more than one Linux computer on your home network.
They are useful on your home Linux server as well, since it clarifies some
configuration settings for some future services you might like to enable,
for example, a web service.

You can only configure the hosts file if you have reserved IP addresses
in your home router for your special devices, like your home Linux server.

The list of files that I like to manage are:

  * /etc/networks
     * Read the man page on 'networks'
     * Add a local domain for your home network here.
       We will call this domain *.home*, that is, if
       your server's short name is *pi*, then its long name becomes *pi.home*
     * Avoid problems -- do not use a valid [Top Level Domain (TLD)][tld].\
       '.home' is not a TLD (at least not yet..)
  * /etc/hosts
     * Read the man page on 'hosts'
     * Add some IP addresses you have reserved in your home router for your
       hostnames
     * Be sure to include your home server

Your router's private network address is used when declaring your home domain;
the private netowrk is typically something like 192.168.1.0
or 10.0.0.0.  I did a quick analysis of a list of
[the IP addresses of common routers][routers].  The network address of the
router is usually obtained by dropping the last octet from its IP address.
The top 4 network addresses (without a trailing .0) were:

  * 192.168.0
  * 192.168.1
  * 192.168.2
  * 10.0.0

Note that your home network's IPv4 address space is always in [the private
network space][private] -- that is, network traffic addressed to devices in
a private network is never routed over the Internet.

The Ubuntu version of the /etc/hosts file automatically puts your hostname 
within the 'localhost' network during installation; we will comment that out.

Here are the examples:

```shell
// File: /etc/networks
// You can look at your router's management web page to understand
// what your network address is - the example used here is: 192.168.1.0
// You can drop the last octet, that is the '.0', but I leave it in:

$ man networks
$ sudo cp -p /etc/networks /etc/networks.orig
$ sudo nano /etc/networks
$ cat /etc/networks
link-local 169.254.0.0
home  192.168.1.0

$ diff /etc/networks.orig /etc/networks
2a3
> home  192.168.1.0

// File: /etc/hosts
// Add your favourite devices with their reserved hostnames to /etc/hosts
// Each host gets it full name with .home attached, as well as its short name
// and any aliases:

$ man hosts
$ sudo cp -p /etc/hosts /etc/hosts.orig
$ sudo nano /etc/hosts
$ # diff /etc/hosts.orig /etc/hosts
2c2
< 127.0.1.1     pi
---
> #127.0.1.1    pi
9a10,13
> 
> 192.168.1.90	pi.home pi www
> 192.168.1.65	desktop.home desktop
> 192.168.1.80	odroid.home odroid
> 192.168.1.81	laptop.home laptop
> 192.168.1.86	inkjet.home inkjet
```

### Changing the Server's Hostname

Now that we have a *.home* domain we can rename our official server's hostname.
Suppose the server was originally named *pi* during the installation:

```shell
// look at what you set your hostname to during the installation:
$ hostname
pi

// Give the server a fully-qualified hostname using 'hostnamectl'
// Note that older versions of hostnamectl required:
//      sudo hostnamectl set-hostname pi.home
$ sudo hostnamectl hostname pi.home

$ hostname
pi.home
```

### The Resolver and Looking Up Your Local Hostnames

Well-known traditional command-line tools for querying DNS [^dns] are:

  * host
  * nslookup
  * dig

These tools look in */etc/resolv.conf* for the nameserver(s) to query
when looking up IP addresses or hostnames.

Of course, external DNS servers know nothing about your private local network.
So, when you try querying a private host using one of the above utilities,
you might see:

```shell
$ host pi.home
pi.home has address 192.168.1.90
Host pi.home not found: 3(NXDOMAIN)
```

The 'host' command looked at the /etc/hosts file, but
might also consulted the listed nameservers.  This is because it consults an
important file named */etc/nsswitch.conf* which configures the order to try
when looking up host and other data.  Because 'files' is first, the
daemon consults /etc/hosts before doing any dns request:

```shell
$ grep hosts /etc/nsswitch.conf
hosts:          files mdns4_minimal [NOTFOUND=return] dns
```


There is another command-line tool -- *getent* -- for looking up local dns data,
and does not consult nameservers:

```shell
$ getent hosts pi
192.168.1.90   pi.home pi web
$ getent hosts 192.168.1.90
192.168.1.90   pi.home pi
```

Contemporary Linux version's using systemd-resolvd handle this case better
since it acts as a local nameserver that handles local DNS lookups, especially
local IP address lookups.  However it still whines about hostname looks, though
it returns the correct local lookup anyway:

```shell
// Try from another ubuntu host:

$ hostname
ubuntu.home

$ host pi
pi has address 192.168.1.90
Host pi not found: 3(NXDOMAIN)
$ echo $?
1

$ host 192.168.1.90
90.1.168.192.in-addr.arpa domain name pointer pi.


// Now from the pi host - NOTE that it will not emit an NXDOMAIN message
// for its own hostname, and thus will return success, which is '0':

$ hostname
pi.home

$ host pi
pi has address 192.168.1.90
$ echo $?
0
```

### Modifying the Resolver's List of Nameservers

The resolver file would typically be created at bootup when your computer
makes a DHCP request to the home router asking for an IP address and the
names of the router's configured DNS servers.

On contemporary Linux versions the resolver file is created and managed
differently than in older Linux versions.  Recent Ubuntu LTS versions
use a systemd service named *systemd-resolved* which by default manages
the resolver file, and it runs a local DNS server:

```shell
// list open network connections and find a name match for 'resolve'
# lsof -i -P -n +c0 | grep resolve
systemd-resolve  568 systemd-resolve   13u  IPv4  20701      0t0  UDP 127.0.0.53:53 
systemd-resolve  568 systemd-resolve   14u  IPv4  20702      0t0  TCP 127.0.0.53:53 (LISTEN)

// This is what the resolver file looks like on a newly installed Ubuntu node
$ tail -3 /etc/resolv.conf 
nameserver 127.0.0.53
options edns0 trust-ad
search .

// the resolver file is actually a symbolic link into territory owned by systemd
$ ls -l /etc/resolv.conf 
lrwxrwxrwx 1 root ... Mar 17 14:38 /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf

// get the resolver's status -- in this example the first DNS server is
// my router's IP address
$ resolvectl status
Global
       Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
resolv.conf mode: stub

Link 2 (ens3)
    Current Scopes: DNS
         Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.1.254
       DNS Servers: 192.168.1.254 75.153.171.67
```

Sometimes you want to modify the list of external DNS servers -- for example --
the DNS servers used by *my* router have 'slow' days, so I like to have
control over the list of DNS servers to fix this issue.  Here is a look
at the process.

Create a local copy of the resolver file - do not pollute systemd space:

```shell
// Remove the current resolver file (we don't want to edit systemd's file).
// This just removes the symbolic link:
$ sudo rm /etc/resolv.conf

// Get a copy of /usr/lib/systemd/resolv.conf for manual control of the resolver
$ sudo cp -p /usr/lib/systemd/resolv.conf /etc/resolv.conf

// Change only the comments at the top to show it is locally managed:
$ sudo nano /etc/resolv.conf

$ tail -3 /etc/resolv.conf
nameserver 127.0.0.53
options edns0 trust-ad
search .
```

By default this version of Ubuntu uses NetworkManager for network configuration,
and the local systemd-resolved for DNS service.  To make a permanent change
to the DNS information known to systemd we configure NetworkManager using
its management utility *nmcli*:

```shell
$ nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  91591311-3c9a-3541-8176-29a8b639fffa  ethernet  eth0   
MY-SSID             924de702-7f7e-4e31-8dff-4bc968148f2b  wifi      --

$ nmcli connection show 'Wired connection 1' | grep -i dns
connection.mdns:                        -1 (default)
connection.dns-over-tls:                -1 (default)
ipv4.dns:                               --
ipv4.dns-search:                        --
ipv4.dns-options:                       --
...
IP4.DNS[1]:                             192.168.1.254
IP4.DNS[2]:                             75.153.171.67
```

Now we add some other DNS servers to this configuration using nmcli; it should
persist after a reboot.  We are adding well-known public IP addresses from
Cloudflare (1.1.1.1), and from Google (8.8.8.8):

<!-- !! I need to check if we need to restart the network.. -->

```shell
$ sudo nmcli connection modify 'Wired connection 1' ipv4.dns "1.1.1.1,8.8.8.8"
$ nmcli connection show 'Wired connection 1' | grep -i dns
connection.mdns:                        -1 (default)
connection.dns-over-tls:                -1 (default)
ipv4.dns:                               1.1.1.1,8.8.8.8
ipv4.dns-search:                        --
...
IP4.DNS[1]:                             1.1.1.1
IP4.DNS[2]:                             8.8.8.8
IP4.DNS[3]:                             192.168.1.254
IP4.DNS[4]:                             75.153.171.67

// Check it with resolvectl:
$ resolvectl status|grep 'DNS Serv'
Current DNS Server: 1.1.1.1
       DNS Servers: 1.1.1.1 8.8.8.8 192.168.1.254 75.153.171.67
```

If ever you want to make a temporary change, use 'resolvctl' to do that; it
will not persist after a reboot:

```shell
// Here the Pi's ethernet device name is 'eth0'
$ sudo resolvectl dns eth0 9.9.9.9 8.8.4.4 75.153.171.67

$ resolvectl status
Global
       Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
resolv.conf mode: foreign
      DNS Domain: ~.

Link 2 (eth0)
    Current Scopes: DNS
         Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 9.9.9.9
       DNS Servers: 9.9.9.9 8.8.4.4 75.153.171.67
```

[tld]: https://data.iana.org/TLD/tlds-alpha-by-domain.txt
[private]: https://en.wikipedia.org/wiki/Private_network
[routers]: https://www.techspot.com/guides/287-default-router-ip-addresses/
[^dns]: Domain Name System -- how we look up hostnames

## Other Ways of Becoming the Superuser in a Restricted Environment {#root}

You might run into a chicken-and-egg problem occasionally because you
need to do something like:

  * move your home directory files
  * fix a problem with logging in as a regular user
  * you accidentally removed the sudo package

Then you realize that you need to be logged in as a regular user to 
sudo to *root*, but you cannot be logged in to accomplish your task.

### Setting a Password for the Superuser

One solution is to set a password for the *root* user - you can always
disable the password afterwards.

This is an example of setting a password for root -- as always you set
a **strong** password:

```shell
// Normally password access is locked in /etc/shadow - we unlock it when
// we set a password:
$ man passwd
$ man 5 passwd
$ sudo /bin/bash
# id
uid=0(root) gid=0(root) groups=0(root)
# head -1 /etc/shadow
root:!:19476:0:99999:7:::
# passwd 
New password: 
Retype new password: 
passwd: password updated successfully

// We now see an encrypted password in the password field in the shadow file:
# head -1 /etc/shadow
root:$y$j9T$FFNwo6b8WAoEu...tQQhPaSIumPjNPXjWAe7h2M4:19519:0:99999:7:::
```

Now we can log in directly as root at the server's text console; remember
that it is foolish to login as 'root' to a graphical environment.  Using
web browers as 'root' is not smart.

To lock the root user from using a password, use the **-l** option; you can
unlock it in the future with the **-u** option.

```shell

// lock it:
# passwd -l root
passwd: password expiry information changed.

# head -1 /etc/shadow
root:!$y$j9T$FFNwo6b8WAoEu...tQQhPaSIumPjNPXjWAe7h2M4:19519:0:99999:7:::
```

### Allowing Secure-shell Access From Another Device in Your LAN

Another solution is to allow another device in your home network to have
secure-shell access to the root account on your Ubuntu server or desktop.  It
is mentioned briefly in the [secure-shell section](#sshd) of this guide, but
I summarize the main options here.

The secure-shell daemon must be installed and running on the target device.
In */etc/ssh/sshd_config* add the remote device's IP address with *root@* 
prefixing it to the 'AllowUsers' rule.  Here access to the root account is
allowed from 192.168.1.65:

```shell
# id
uid=0(root) gid=0(root) groups=0(root)
# grep AllowUsers /etc/ssh/sshd_config
AllowUsers      myname@192.168.1.* root@192.168.1.65 *@localhost
```

Then root's */root/.ssh/authorized_keys* file must specifically allow the
remote device; in this case we use the *from=''* option (see the man page for
'authorized_keys').  As well, if you also allow localhost (127.0.0.1) you would
allow your login account to ssh locally to root:

```shell
# tail -1 ~/.ssh/authorized_keys
from="127.0.0.1,192.168.1.65" ssh-rsa AAAAB3...6oLYnLx5d myname@somewhere.com

$ whoami
myname

$ ssh -A -Y root@localhost
Last login: Tue Jun 13 15:10:42 2023 from desktop.home
# ps -ef --forest|grep ssh
root       685       1  May26 ?      00:00:00 sshd: /usr/sbin/sshd -D [listener] ...
root    395328     685  09:27 ?      00:00:00  \_ sshd: myname [priv]
myname  395330  395328  09:27 ?      00:00:00  |   \_ sshd: myname@pts/0
myname  395414  395331  09:29 pts/0  00:00:00  |           \_ ssh -A -Y root@localhost
root    395415     685  09:29 ?      00:00:00  \_ sshd: root@pts/1
root    395460  395429  09:30 pts/1  00:00:00          \_ grep --color=auto ssh
myname    3693       1  May26 ?      00:00:00 ssh-agent
```

## Creating a New Git Repository {#new-git-repo}

This is a list of small tasks that you as the git manager must do for
each new repository that you host on your Git server:

   * Initialize the repository
   * Create a symbolic link to the repository's name without the '.git' extension
   * Edit the 'description' file with a one-line description
   * Touch the git-daemon-export-ok file to enable exporting the repository
   * Add the repository name and author to the projects list file

```shell
$ sudo -u git /bin/bash

// Let's go ahead and create a git repository named 'test'.
// We do this by using the git 'init' command:
$ cd /git
$ git --bare init test.git
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint:   git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint:   git branch -m <name>
Initialized empty Git repository in /var/www/git/test.git/

$ ls -l
drwxr-xr-x 7 git git 4096 Jul  6 14:52 test.git

// Create the symbolic link without the 'git' extension
$ ln -s test.git test

// We create a repository description, and we export the repository so that
// it is visible:
$ nano test.git/description
$ cat test.git/description
This is just a test.

$ cd test.git/
$ ls
branches  config  description  HEAD  hooks  info  objects  refs

$ touch git-daemon-export-ok

// Finally we add the repository name and author to the projects list file.
// This file is used by 'gitweb', and it's name is in '/etc/gitweb.conf'
// You must create the file the first time you create a new repository:
$ cd /git
$ touch projects_list_for_homegit
$ nano projects_list_for_homegit
$ cat projects_list_for_homegit 
test MyFirstName+MyLastName

$ exit
```

## Allowing a New User SSH Access to the Git Server {#new-git-user}

One time only we set up the authorized keys file.

```shell
$ sudo -u git /bin/bash
$ cd
$ pwd
/home/git
$ mkdir .ssh
$ chmod go-rwx .ssh
$ touch .ssh/authorized_keys
$ chmod 600 .ssh/authorized_keys
```

Then for each new user whom we allow to use ssh access to git repositories
we need to add their designated public ssh key.

```shell
// add public keys for allowed users, starting with yourself
$ nano .ssh/authorized_keys
$ tail -1 authorized_keys
ssh-rsa AAAAB3...6oLYnLx5d myname@somewhere.com
```

<!-- !! Note about IPv6 -->
<!-- Yet to do: Command-line Index  -->
<!-- Yet to do: URL Index  -->

