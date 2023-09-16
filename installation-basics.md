<!-- -->
# Installation and first experience {#chapter-04}

Once you have prepared your microSD card then insert it in your Raspberry Pi.
Note that the card pushes in easily.  It will only go in one way.
On a Pi 400 you can eject it by gently *pushing on it once* and it will pop
out enough to grab it.  There is no need to pull on it to remove it because
it essentially pops out.  With a Pi 4b you will need to pull it out.

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

## Getting Going with the Command-Line

For people without much command-line experience it is important to get going
at the command-line.  When logged into the MATE desktop open a terminal
window by selecting Application -> System Tools -> MATE Terminal.

Try [some command-line examples](#eg-cmds) in the appendix.  Note that
the up/down arrow keys can be used to recall your previous commands.
You can edit and reuse an entry in your previous commands using
the left/right arrow keys.

You will find that the 'TAB' key (shown below as *\<TAB\>*) is very useful
for command-line completion.

Suppose you are going to use the command 'timedatectl'.  You start by typing
the word 'time' and then hit the TAB key once, then again when you do not get a
response.  You will see 4 possible commands as shown below.  Then to complete
the command simply type d followed by another TAB and the full command will 
complete:

```console
$ time<TAB><TAB>
time         timedatectl  timeout      times
$ timed<TAB>
$ timedatectl 
```

Look online for some tutorials; there are millions of results on Google if you
search for:

~~~~ 
    Linux "command line" tutorial for beginners
~~~~ 

See also the [list of all commands used in this guide](#command-list).

