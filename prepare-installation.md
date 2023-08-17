<!-- -->
# Creating the installation disk {#image}

You will need a new or repurposed microSD card with a capacity of at
least 32 GB -- since this is a server we might want to store lots of photos
or videos on it.  See [the Ubuntu MATE website][ubuntu-mate] for some
examples of microSD cards.  Recently I was able to buy a 256 GB Silicon Power
microSD card for less than $25 Cdn on Amazon; this brand is rated highly
for use on Raspberry Pi's by testers like [Tom's Hardware][toms].

Go to 
[the Ubuntu MATE download website][download]
to download your image - for a Pi 4 generation with 4 or more GB of RAM
the 64-bit ARM architecture (arm64) is best.  For the version I used in
March 2023 the image name was: \
  *ubuntu-mate-22.04-desktop-arm64+raspi.img.xz*.

There are many instructions available online to help
you download the disk image and install it onto installation media -
I will not reproduce the instructions here.  How you create the
image depends on your home computing device and its OS.
There is a helpful [tutorial][tutorial] on creating
the installation image using the Raspberry Pi Imager software for 3 operating
systems:

  * [Windows OS][windows]
  * [MacOS][macos]
  * [Debian-based Linux][debian]

Note that after installing the disk image on the microSD the disk partitioning
looks like this.  I only show it here so that you are aware of what is going
on under the hood.  Here is an example of a 256 GB microSD inserted into a
USB card reader on another Linux computer where the card showed up as /dev/sde:

```shell
$ sudo fdisk -l /dev/sde
Disk /dev/sde: 231.68 GiB, 248765218816 bytes, 485869568 sectors
Disk model: FCR-HS3       -3
...
Disklabel type: dos
Disk identifier: 0x11d94b9e

Device     Boot  Start      End  Sectors  Size Id Type
/dev/sde1  *      2048   499711   497664  243M  c W95 FAT32 (LBA)
/dev/sde2       499712 12969983 12470272  5.9G 83 Linux
```

So there are 2 partitions; the first (/dev/sde1) is a small boot partition
whose type is FAT32, and the second (/dev/sde2) is the minimal 6 GB Linux
partition.  Though this microSD is 256 GB only the first 6 GB is currently used.
The automatic installation process will expand the partition right to the
maximum extend of its partition or of unallocated space.  Most Linux
installation images allow you to choose your disk partitioning; the
Raspberry Pi installation image does not.

However, it is possible and useful to
[modify the pre-installation partitioning](#mod-partition)
directly on the microSD card as described in the appendix.

In the appendix I also provide a generic Linux
[command-line approach](#image-cmds) to downloading, uncompressing and
writing the image to the microSD card.
If you are not yet very familiar with the command-line then leave this
exercise for a later time in your Linux adventure.

[ubuntu-mate]: https://ubuntu-mate.org/raspberry-pi/
[download]: https://ubuntu-mate.org/raspberry-pi/download/
[toms]: https://www.tomshardware.com/best-picks/raspberry-pi-microsd-cards
[tutorial]: https://ubuntu.com/tutorials/how-to-install-ubuntu-desktop-on-raspberry-pi-4#2-prepare-the-sd-card
[windows]: https://downloads.raspberrypi.org/imager/imager_latest.exe
[macos]: https://downloads.raspberrypi.org/imager/imager_latest.dmg
[debian]: https://downloads.raspberrypi.org/imager/imager_latest_amd64.deb

