<!-- -->
# Installation and First Experience

Once you have prepared your microSD card then insert it in your Raspberry Pi.
Note that the card pushes in easily.  It will only go in one way.
To eject it gently push *in* on it once and it will pop out enough to handle it.
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

```shell
// This will update the system's knowledge about what should be updated;
// in other works, the cache of software package names pending for update:
$ sudo apt update

// then update the software; the command is actually 'upgrade', which is odd,
// at least to me..
$ sudo apt upgrade
```

It will take a while.  Once finished reboot the system to get the newer
kernel.  On the far upper right taskbar, select the powerbutton icon,
and then select  *Switch Off* -> *Restart*.

<!-- (!!) add a note about unmounting the PI-DATA volume at some point after
installation -->

