<!-- -->
# Picking the OS (Operating System) and the Window Manager {#environment}

Though many Raspberry Pi owners run the Raspberry Pi OS (formerly known
as Raspbian), in this guide I chose to use Ubuntu.
[Ubuntu LTS][ubuntu-lts], 
is a long-term support Debian-based Linux OS. Ubuntu is renowned for
its desktop support,
but it also provides a comfortable home server experience.  A server
should be stable.  We want to apply software updates, but we also
want to avoid the need to update the major version of the base OS every
year.  The Official Gnome LTS releases with the Gnome desktop environment
in the *main* software repository are supported for up to 5
years from initial release, and up to 10 years with extended security-only
updates via [Ubuntu Advantage][advantage] access[^pro]. However if you do
not have an *advantage* account, then 
community-supported desktop environments which are located in the
*universe* software repository only get 3 years of support, meaning
system-wide there is only partial support after 3 years.  Nonetheless,
many critical services are installed from the base repository, and they
have the usual 5 years of support.

Generally you should think about updating your server OS every few
years so that you stay in touch with current technologies.

At the time of writing this guide I used version 22.04 of Ubuntu LTS
(also known as **Jammy Jellyfish**). It was first released in April 2022,
as indicated by the release number.

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
[mate-desktop]: https://mate-desktop.org/
[x.org]: https://en.wikipedia.org/wiki/X.Org_Server
[wayland]: https://en.wikipedia.org/wiki/Wayland_(protocol)#Wayland_compositors
[^pro]: Ubuntu Advantage is also known as **Ubuntu Pro**.  It is *free*
of charge for personal use on up to 5 machines.

