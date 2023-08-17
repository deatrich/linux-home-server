<!-- -->
# Picking the OS (Operating System) and the window manager {#environment}

## Ubuntu LTS

Though many Raspberry Pi owners run the Raspberry Pi OS (formerly known
as Raspbian), in this guide I chose to use Ubuntu.  [Ubuntu LTS][ubuntu-lts] 
is a long-term support Debian-based Linux OS. Ubuntu is renowned for
its desktop support, but it also provides a comfortable home server experience.

A server should be stable.  We want to apply software updates, but we also
want to avoid the need to update the major version of the base OS every
year.  The Official Gnome LTS releases with the Gnome desktop environment
in the *main* software repository are supported for up to 5
years from the time of the initial release, and for up to 10 years with
extended security-only updates via [Ubuntu Advantage][advantage] access[^pro],
also known as *Expanded Security Maintenance* (ESM).

Without ESM not all repositories get the same level of support.  For example,
the community-supported desktop environments located in the
*universe* software repository only get best-effort maintenance from Canonical
and the Ubuntu community.  Nonetheless, most critical services are installed
from the base repository, and thus have excellent functional and security
support.

However with an *ESM/Advantage/Pro* account, then all packages get security
updates for 10 years from initial release.  This change was introduced [in
January of 2023][pro-faq].

As with all OS distributions the versions of major software stay with the
initial release, and patches to the software are for bugs and security issues
for those software versions.

Generally you should think about upgrading your server OS every few
years so that you stay in touch with current technologies, and so that
you benefit from newer software versions.

At the time of writing this guide I used version 22.04 of Ubuntu LTS
(also known as **Jammy Jellyfish**). It was first released in April 2022,
as indicated by the release number.

## Subscribing to a few mailing lists

If you are a going to be using Ubuntu then it is wise to subscribe to a few
mailing lists.  There are [lots of them][ubmail-lists], but a few low volume
ones like these are a good idea:

  * [Ubuntu Security Announce][ubmail-security]
     * Low-traffic announcement list for notifications of security updates for Ubuntu

  * [Ubuntu Announce][ubmail-announce]
     * Low-traffic Ubuntu Announcements

## MATE desktop

I also opt to use an installation image which uses the
[MATE desktop system][mate-desktop]  -- at the bottom of that
linked website is a note about why it is called MATE (pronounced mat-ay).
The MATE window manager is intuitive, efficient, skinny, dependable and
popular. It is widely available on most flavours of Linux.  MATE is not
flashy, but it gets the job done.

Even though we are creating a home server, it is useful to configure the
server to provide a remote graphical desktop environment -- this is why
in this guide we use the desktop image rather than the server image.  Then
you can use the desktop for fun, learning, or perhaps as your Linux development
environment from other devices.  Accessing the desktop remotely is also
documented in this guide.

This installation image still uses the [X.org display server][x.org]
instead of [Wayland][wayland], partly because it uses MATE which
is not yet ready for Wayland at this Ubuntu LTS release, and also because
this build is for the Raspberry Pi, where Wayland support is new.  Moreover
remote desktop support is a work in progress for Wayland environments, and is
better left to the X.org protocol for now.

[ubuntu-lts]: https://releases.ubuntu.com/
[advantage]: https://ubuntu.com/pro/tutorial
[ubmail-lists]: https://lists.ubuntu.com/
[ubmail-security]: https://lists.ubuntu.com/mailman/listinfo/ubuntu-security-announce
[ubmail-announce]: https://lists.ubuntu.com/mailman/listinfo/ubuntu-announce

[mate-desktop]: https://mate-desktop.org/
[x.org]: https://en.wikipedia.org/wiki/X.Org_Server
[wayland]: https://en.wikipedia.org/wiki/Wayland_(protocol)#Wayland_compositors

[^pro]: Ubuntu Advantage is also known as **Ubuntu Pro**.  It is *free*
of charge for personal use on up to 5 machines.

[pro-faq]: https://discourse.ubuntu.com/t/ubuntu-pro-faq/34042

