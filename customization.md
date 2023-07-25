<!-- -->
# Server Customization

Here is a list of tasks you can apply to your server for 24x7 service.
Ubuntu installations are more common on laptops and desktops which
are often connected via wireless, are turned on and off frequently, and have
a lot of software configuration not usually present or needed on a server.

The main objective here is to show you some options that reduce
complexity and memory consumption, and might improve security and reliability.
You can always circle back here in the future and try them.

By all means, ignore all of this if you don't want to be bothered with 
disabling extraneous software.  I have spent 3 decades managing UNIX and
Linux systems, so I can be a bit picky about what runs on my systems.

## Turn Off Bluetooth

If you won't be using it on your server then turn Bluetooth off.

The Pi does not have a BIOS like personal computers do; instead configuration
changes to enable or disable devices are managed in the configuration file
*config.txt* in */boot/firmware/*

<!-- at some point discuss the lack of a RTC and its effect
on logging, etc. on SBC devices -->

You will need to eventually reboot the server once you have make this change.
If you also disable WiFi then wait until you have finished the next task, or
any other tasks in this chapter.

```shell
// List bluetooth devices:
$ hcitool dev
Devices:
        hci0    E4:5F:01:A7:11:0F

// disable bluetooth services running on the Pi
$ sudo systemctl disable blueman-mechanism bluetooth

// Always save a copy of the original file with the 'cp' command:
$ cd /boot/firmware
$ sudo cp -p config.txt config.txt.orig
// Disable bluetooth in config.txt by adding 'dtoverlay=disable-bt' at the end
$ sudo nano config.txt
// Use the 'tail' command to see the end of the file:
$ tail -3 config.txt

dtoverlay=disable-bt
```

## Turn Off Wireless

If you will use the built-in ethernet interface for networking on your server
then turn WiFi off.  I prefer wired connections for servers, especially since
newer technology offers gigabit speed ethernet.  In my experience, the network
latency is usually better to wired devices.  But if you prefer to keep the
server on wireless then skip this task.

You will need to reboot the server once you have make this change, but 
**remember to connect the ethernet cable** on the Pi to your home router first!

```shell
// List wireless devices - after making this change you will not see this
// information:
$ iw dev
phy#0
        Unnamed/non-netdev interface
                wdev 0x2
                addr e6:5f:01:a7:71:0d
                type P2P-device
                txpower 31.00 dBm
        Interface wlan0
                ifindex 3
                wdev 0x1
                addr e4:5f:01:a7:22:55
                ssid MYNET
                type managed
                channel 104 (5520 MHz), width: 80 MHz, center1: 5530 MHz
                txpower 31.00 dBm

// Disable wireless in config.txt by adding 'dtoverlay=disable-wifi' at the end
$ cd /boot/firmware
$ sudo nano config.txt
// Use the 'tail' command to see the end of the file:
# tail -3 config.txt

dtoverlay=disable-bt
dtoverlay=disable-wifi

// After rebooting the Pi disable the wireless authentication service
$ sudo systemctl stop wpa_supplicant
$ sudo systemctl disable wpa_supplicant
```
### Consider Enabling a Static IP Configuration
Normally you get your network configuration from your home router via its DHCP
service.  If you are using a wired connection then consider statically
configuring the IP address information on your server -- there is
[a description of the process](#static-ip) in the appendix in case you
want to see how it is done.

## Enable Boot-up Console Messages

Maybe like me you like seeing informational messages as a computer boots up.
In that case you need to edit */boot/firmware/cmdline.txt* and remove
the 'quiet' argument.  On my system this one line file nows ends in:\
  '... fixrtc splash'\
instead of\
  '... fixrtc quiet splash':

```shell
$ cd /boot/firmware
$ sudo cp -p cmdline.txt cmdline.txt.orig
$ sudo nano cmdline.txt
```

## Disable the Graphical Login Interface

Simpler is better for a server.  Normally 24x7 servers are headless, mouseless,
keyboardless, and sit in the semi-darkness.  A graphics-based console
is therefore useless.  Though your home server might not be as lonely as a
data centre server, you might want to try a text-based console:

```shell
$ sudo systemctl set-default multi-user
$ sudo systemctl stop display-manager

// If you do have a mouse and a screen attached then you can still make 
// the mouse work in a text console login -- it can be useful.  At work
// I have sometimes used the mouse at a console switch to quickly copy and
// paste process numbers for the kill command.

$ sudo apt install gpm
$ sudo systemctl enable gpm
```

## Disable Snap Infrastructure

Ubuntu promotes another kind of software packaging called **Snaps** (which
includes an *App* store).  Some users are not pleased with issues introduced
by the underlying support software, and decide to
[delete Snap support][remove-snap] from their systems.  In my early testing
of Ubuntu LTS 22.04 I also ran into the problem of firefox not able to
start, and like others I traced it back to snap (firefox is installed
from a Snap package).

I don't think 'Snaps' are meant for a server environment, and so I remove
the associated software.  I certainly find it distasteful to have more
than a dozen mounted loop devices cluttering up output of block device commands
for just a handful of snap packages.  I would rather free up the memory
footprint and inodes for other purposes.

So here is a quick summary on removing Snap support, that is, all snap
packages and the snapd daemon:

#### Disable the daemon

You should close firefox if it is running in a desktop setting.  Then
disable the snapd services and socket:

```shell
$ sudo systemctl disable snapd snapd.seeded snapd.socket
```

#### Remove the packages

List the Snap packages installed, and then delete them.  Leave *base* and
*snapd* packages until the end.  As noted in [Erica's instructions][snap-remove]
remove packages one at a time and watch for messages warning about 
dependencies.  This is my list of Snap packages; your list might be different
depending on what you have installed:

```shell
$ snap list
Name                       Version           ...  Publisher      Notes
bare                       1.0               ...  canonical     base
core20                     20230404          ...  canonical     base
core22                     20230404          ...  canonical     base
firefox                    112.0.2-1         ...  mozilla       -
gnome-3-38-2004            0+git.6f39565     ...  canonical     -
gnome-42-2204              0+git.587e965     ...  canonical     -
gtk-common-themes          0.1-81-g442e511   ...  canonical     -
snapd                      2.59.2            ...  canonical     snapd
snapd-desktop-integration  0.9               ...  canonical     -
software-boutique          0+git.0fdcecc     ...  flexiondotorg classic
ubuntu-mate-pi             0+git.0f0bcdf     ...  ubuntu-mate   -
ubuntu-mate-welcome        22.04.0-a59036a6  ...  flexiondotorg classic

$ sudo snap remove firefox
$ sudo snap remove software-boutique
$ sudo snap remove ubuntu-mate-welcome
$ sudo snap remove ubuntu-mate-pi
$ sudo snap remove snapd-desktop-integration
$ sudo snap remove gtk-common-themes
$ sudo snap remove gnome-42-2204
$ sudo snap remove gnome-3-38-2004
$ sudo snap remove core22
$ sudo snap remove core20
$ sudo snap remove bare
$ sudo snap remove snapd

$ snap list
No snaps are installed yet. Try 'snap install hello-world'.
```

#### Clean up and add a new firefox dpkg source

Completely remove snapd and its cache files from the system.  Then add 
configuration files for *apt* access to firefox *dpkg-based* packages.
Finally install firefox from the Mozilla Personal Package Archive (PPA):

```shell
$ sudo apt autoremove --purge snapd
$ sudo rm -rf /root/snap
$ rm -rf ~/snap

// Create the necessary apt configurations for firefox:

$ sudo nano /etc/apt/preferences.d/firefox-no-snap
$ cat /etc/apt/preferences.d/firefox-no-snap
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1

$ sudo add-apt-repository ppa:mozillateam/ppa
...
PPA publishes dbgsym, you may need to include 'main/debug' component
Repository: 'deb https://ppa.launchpadcontent.net/.../ppa/ubuntu/ jammy main'
Description:
Mozilla Team's Firefox stable + 102 ESR and Thunderbird 102 stable builds
Support for Ubuntu 16.04 ESM is included.
...

// Install firefox
$ sudo apt install firefox
```

[remove-snap]: https://onlinux.systems/guides/20220524_how-to-disable-and-remove-snap-on-ubuntu-2204

## Modify the Swap Setup

There is a big 1 GB [swapfile][swap] in the root of the filesystem - I find
that offensive, so I moved it.  If you are not as easily offended as I am
then skip this topic.

It is a good idea to have some kind of swap enabled, since swap is only used
if too much memory is being consumed by processes.  Once memory is low the
system will start using any configured swap on disk.  Of course this is slower
than memory, but it is better to use some swap at those moments instead of 
having an unfortunate process die [because of an out-of-memory condition][OOM].

Over time if you never see swap being used then you could turn swap off and 
delete the swap file.

Here we create another 1 GB file -- it can be much larger if needed; but 
if you need a lot of swap then you should investigate to see what is eating
memory.

```shell
// check to see what the current swap usage is; in this case it is 0
$ free -t
           total       used        free    shared  buff/cache   available
Mem:     3881060     176900     3022600      5332      681560     3541748
Swap:    1048572          0     1048572
Total:   4929632     176900     4071172

// Look at what systemd does with swap, and turn off the appropriate items
$ systemctl list-unit-files | grep swap
mkswap.service                              disabled        enabled
swapfile.swap                               static          -
swap.target                                 static          -

// There will be a .swap rule for every swap file - this one is for /swapfile
// and we want to get rid of it
$ sudo systemctl mask swapfile.swap
Created symlink /etc/systemd/system/swapfile.swap → /dev/null.

// Even though the 'mkswap' service is by default disabled, I also
// mask it so that it doesn't come back from the dead - because it
// will come back if you don't also mask that service
$ sudo systemctl mask mkswap.service
Created symlink /etc/systemd/system/mkswap.service → /dev/null.

// turn current swap off so we can delete the old file
$ sudo swapoff -a
$ sudo rm /swapfile

// Create an new swapfile in a subdirectory
$ sudo mkdir /swap
$ sudo fallocate -l 1G /swap/swapfile
$ sudo mkswap /swap/swapfile
Setting up swapspace version 1, size = 1024 MiB (1073737728 bytes)
no label, UUID=3e64d157-6f09-48d1-94c2-3851b82a73b7

// Protect the swap file and add it to /etc/fstab
$ sudo chmod 600 /swap/swapfile
$ sudo nano /etc/fstab
$ grep swap /etc/fstab
/swap/swapfile    none           swap defaults     0 0

// Turn swap back on and check
$ sudo swapon -a
$ swapon
NAME           TYPE  SIZE USED PRIO
/swap/swapfile file 1024M   0B   -2

// Note that systemd will show a new 'swap' type named 'swap-swapfile.swap'
$ systemctl --type swap 
  UNIT               LOAD   ACTIVE SUB    DESCRIPTION   
  swap-swapfile.swap loaded active active /swap/swapfile
```

[OOM]: https://docs.memset.com/cd/Linux%27s-OOM-Process-Killer.199066633.html
[swap]: https://help.ubuntu.com/community/SwapFaq


## Remove **anacron** Service

UNIX and Linux has a mechanism called *cron* allowing servers to run
commands at specific times and days.  However personal and mobile computing is
typically not powered on all the time.  So operating systems like Linux 
have another mechanism called *anacron* which trys to run periodic 
cron-configured commands while the computer is still running.  Since we 
are creating a 24x7 server we do not also need anacron -- delete it:

```shell
$ sudo apt remove anacron
$ sudo apt purge anacron
```

## Disable Various Unused Services

Here are some services which normally can be disabled.  Of course, if any
of these services are interesting to you then keep them.  Note that server
processes are sometimes called *daemons*.

The *systemctl* command can handle multiple services at the same time, but
doing them individually allows you to watch for any feedback.  You can also
simply disable these services without stopping them.  They will not run
on the next reboot.

```shell
// If you want to run a series of commands as root you can sudo to the bash
// shell, run your commands, and then exit the shell.  Be careful to
// always exit immediately after running your commands.
$ sudo /bin/bash

// disable serial and bluetooth modems or serial devices
# systemctl stop ModemManager
# systemctl disable ModemManager
# systemctl stop hciuart
# systemctl disable hciuart

// disable VPN and printing services - you can print without running
// a local printer daemon (!!maybe document using one tho )
# systemctl stop openvpn
# systemctl disable openvpn
# systemctl stop cups-browsed cups
# systemctl disable cups-browsed cups

// disable System Security Services Daemon ([sssd][sssd]) if you don't need it
# systemctl disable sssd

// Disable UEFI Secure Boot (secureboot-db)
// 
# systemctl disable secureboot-db

// disable whoopsie and kerneloops if you don't want to be sending
// information to outside entities
# systemctl stop kerneloops
# systemctl disable kerneloops
# systemctl stop whoopsie
# systemctl disable whoopsie
# apt remove whoopsie kerneloops
# apt purge whoopsie kerneloops

// If you want to disable other apport-based crash reporting then remove apport
// from your server:
# apt autoremove --purge apport
```

[sssd]: https://ubuntu.com/server/docs/service-sssd

## Miscellaneous Configuration Tweaks

### Change Local Time Presentation Globally

If you prefer to see time in 24 hour format, or if you prefer to tweak
other [locale][locale] settings, then use *localectl* to set global
locale settings.

In this example the locale setting is generic English with a region code
for Canada.  Because the British English locale uses a 24 hour clock then
changing only the time locale will show datestrings with a 24 hour clock:

```shell
// Show your current locale settings
$ locale
LANG=en_CA.UTF-8
LANGUAGE=en_CA:en
LC_CTYPE="en_CA.UTF-8"
LC_NUMERIC="en_CA.UTF-8"
LC_TIME=en_CA.UTF-8
LC_TIME=en_GB.UTF-8
...

// What the date is in the current (Canadian) locale
$ date
Thu 11 May 2023 08:43:57 AM MDT

// What the date would look like if (American) en_US.UTF-8 were used:
$ LC_TIME=en_US.UTF-8 date
Thu May 11 08:45:18 AM MDT 2023

// What the date would look like if (British) en_GB.UTF-8 were used:
$ LC_TIME=en_GB.UTF-8 date
Thu 11 May 08:44:00 MDT 2023

// Change it to the British style.  The change is immediate, but since
// you inherit the older locale environment at login, then you will not see
// the change until you logout, and then back in.
$ sudo localectl set-locale LC_TIME="en_GB.UTF-8"
```

[locale]: https://en.wikipedia.org/wiki/Locale_(computer_software)

### Change Log Rotation File Naming

Ubuntu installs a log rotation package which controls how log files are
rotated on your server.  This package typically once a week compresses log
files to a different name in /var/log/ and truncates the current log.  The
resulting files are rotated through a specified rotation, and the oldest
compressed log is deleted; for example here are 4 weeks worth of rotated
auth.log files:

```shell
$ ls -ltr /var/log/ | grep auth.log
-rw-r-----  1 syslog     adm      3498 Apr 15 23:17 auth.log.4.gz
-rw-r-----  1 syslog     adm      8178 Apr 22 23:17 auth.log.3.gz
-rw-r-----  1 syslog     adm      7225 Apr 30 01:09 auth.log.2.gz
-rw-r-----  1 syslog     adm     58810 May  7 00:22 auth.log.1
-rw-r-----  1 syslog     adm     46426 May 11 09:17 auth.log
```

A better scheme is to use the 'dateext' option in */etc/logrotate.conf*
so that older compressed logs keep their compressed and dated names until
they are deleted:

```shell
$ ls -ltr /var/log/ | grep auth.log
-rw-r----- 1 syslog      adm      3287 Apr 17 07:30 auth.log-20230417.gz
-rw-r----- 1 syslog      adm      2494 Apr 23 07:30 auth.log-20230423.gz
-rw-r----- 1 syslog      adm      4495 May  1 07:30 auth.log-20230501.gz
-rw-r----- 1 syslog      adm     35715 May  7 07:30 auth.log-20230507
-rw-r----- 1 syslog      adm     29500 May 11 09:55 auth.log
```

To make this change /etc/logrotate.conf is modified.  We also set the
number of rotations to keep to 12 weeks instead of 4 weeks.  Note that
per-service log file customization is possible; look at examples in
*/etc/logrotate.d/*

```shell
$ cd /etc
$ sudo cp -p logrotate.conf logrotate.conf.orig
$ sudo nano logrotate.conf
$ diff logrotate.conf.orig logrotate.conf
13c13,14
< rotate 4
---
> #rotate 4
> rotate 12
19c20
< #dateext
---
> dateext
```

### Other Configuration Issues

These topics will be documented soon: 

  * automatically or manually managing software updates
  * point to LAN configuration, in particular, static configuration for your server 
  * explore firewall issues - ufw seems lacking
  * getting rid of ESM messages in terminal logins
  * local time configuration and ntp configuration

