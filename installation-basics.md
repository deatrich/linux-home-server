<!-- -->
# Installation and first experience {#chapter-04}

Once you have prepared your microSD card then insert it in your Raspberry Pi.
Note that the card pushes in easily.  It will only go in one way.
To eject it, gently *push in* on it once and it will pop out enough to grab it.
There is no need to pull on it to remove it because it essentially pops out.

Turn the power on with the Pi connected to a monitor, USB keyboard and mouse.
You will shortly see the firmware rainbow splash screen.  Shortly after that
there are a series of screens allowing you to customize the installation:

  * pick your language
  * pick the keyboard layout language
  * enable the Wi-Fi network access if you want to have concurrent updates
  * select your timezone by clicking on your timezone region
  * enter your preferred name and your login name with a password -- this
    is your login account

As the installation starts it will show some informational screens to
entertain you while it installs.  Eventually it will reboot and present you
with the login screen.  Once you login you will see the default MATE
desktop configuration.

Before going further immediately update the software on the system.  The
MATE installation image is not released often, so it can be a bit behind
the package update curve.  As well, any final configuration issues will
be updated.

Open a terminal window by selecting:\
   Application -> System Tools -> MATE Terminal\
and enter the following commands:

```console
// This will update the system's knowledge about what should be updated;
// in other works, the cache of software package names pending for update:
$ sudo apt update

// then update the software; the command is actually 'upgrade', which is odd,
// at least to me.. I like 'yum check-update' and 'yum update' much better...
$ sudo apt upgrade
```

It will take a while.  Once finished there is one more update to do before
you reboot the system -- the Raspberry Pi bootloader EEPROM update, in case
there are pending updates to apply:

```console
// You can check the current state of firmware updates without being root.
// Here we see that the firmware is up-to-date, but the default bootloader
// could be set to use the latest firmware:
$ rpi-eeprom-update
*** UPDATE AVAILABLE ***
BOOTLOADER: update available
   CURRENT: Thu 29 Apr 16:11:25 UTC 2021 (1619712685)
    LATEST: Tue 25 Jan 14:30:41 UTC 2022 (1643121041)
   RELEASE: default (/lib/firmware/raspberrypi/bootloader/default)
            Use raspi-config to change the release.

  VL805_FW: Using bootloader EEPROM
     VL805: up to date
   CURRENT: 000138a1
    LATEST: 000138a1

// no we need to be root since we go ahead and apply the update:
$ sudo rpi-eeprom-update -a
*** INSTALLING EEPROM UPDATES ***
...
EEPROM updates pending. Please reboot to apply the update.
To cancel a pending update run "sudo rpi-eeprom-update -r".
```

Now reboot the server to get the newer kernel, and to complete the firmware
update.  On the far upper right taskbar, select the power button icon,
and then select  *Switch Off* -> *Restart*.

