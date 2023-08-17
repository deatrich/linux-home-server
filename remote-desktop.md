<!-- -->
# Enabling remote desktop services

In case you have various devices at home that you would like to use in a Linux
desktop fashion, but you do not want to change the current environment
on those devices, then you can configure your home Linux server to provide
that opportunity.

For all remote desktop options, first create an *.Xsession* file in your 
home directory on the server and configure it to start a MATE desktop session:

```shell
$ cd
$ nano .Xsession
$ cat .Xsession
/usr/bin/mate-session
```

## Configure Remote Desktop Protocol (RDP)

Most operating systems have client support for Microsoft's Remote Desktop
Protocol.  On Linux there is also a software package named *xrdp*
which can provide RDP.

Note that RDP is [typically not really secure][secure-rdp] without
adding some additional security features.  However, from within your
home network xrdp is okay.

We install xrdp, tweak the configuration a little, and restart xrdp:

```shell
$ sudo apt install xrdp
...
The following additional packages will be installed:
  xorgxrdp
...
Setting up xrdp (0.9.17-2ubuntu2) ...

Generating 2048 bit rsa key...

ssl_gen_key_xrdp1 ok

saving to /etc/xrdp/rsakeys.ini

Created symlink /etc/systemd/system/multi-user.target.wants/xrdp-sesman.service ...
Created symlink /etc/systemd/system/multi-user.target.wants/xrdp.service ...
Setting up xorgxrdp (1:0.2.17-1build1) ...
...

// The configuration file is xrdp.ini; here we disable ipv6 by stipulating
// 'tcp://:3389' in the port configuration:
$ cd /etc/xrdp
$ sudo cp -p xrdp.ini xrdp.ini.orig
$ sudo nano xrdp.ini
$ diff xrdp.ini.orig xrdp.ini
23c23,24
< port=3389
---
> ;;port=3389
> port=tcp://:3389

// restart xrdp
$ sudo systemctl restart xrdp
```

You can test the setup from any other linux computer with
[*remmina*][remmina] installed, or you can secure-shell into
the Linux server with X11 forwarding using the '-Y' option
and run 'remmina' from the command-line; that is:

```shell
// Suppose that your server is named pi.home
$ ssh -Y pi.home

// Test if X11 forwarding is working:
$ xhost
access control enabled, only authorized clients can connect
SI:localuser:myname


// If remmina is not installed, then install it:
$ sudo apt install remmina
$ remmina

// Start remmina and log into the server with your username and password.
// You can save a connection profile with a custom resolution setting
// to get the best possible presentation.
```

There are many web-based tutorials; check out
[*XRDP on Ubuntu 22.04*][xrdp-tutorial].  This tutorial shows how to connect
from Windows and from macOS as well.

[secure-rdp]: https://threatpost.com/remote-desktop-protocol-secure/167719/
[remmina]: https://ubuntu.com/tutorials/access-remote-desktop#1-overview
[xrdp-tutorial]: https://www.digitalocean.com/community/tutorials/how-to-enable-remote-desktop-protocol-using-xrdp-on-ubuntu-22-04

## Configure X2Go 

[X2Go][X2Go] is my favourite remote desktop setup since it runs seamlessly
via secure shell connections and can use [SSH key pairs](#key-pair)
to avoid password use.  Thus I can comfortably connect as a remote desktop
to remote servers across the continent, and write and test code
as if I was down the hall from the remote server.

```shell
// install both the server and the client software
$ sudo apt install x2goserver x2goclient
...
Setting up x2goserver-x2goagent (4.1.0.3-5) ...
Setting up x2goserver (4.1.0.3-5) ...
Created symlink /etc/systemd/system/multi-user.target.wants/x2goserver.service
...

$ systemctl list-unit-files | grep -i x2go
x2goserver.service                         enabled         enabled
```

Your local desktop must have *x2goclient* installed so that you can
start a remote X2Go desktop.  From any Linux desktop running an X.org
service you can start it from the command-line.  This way the client
inherits the SSH environment variables (you can also embed a small 
shell script which provides the environment in a custom application launcher).

```shell
// Bring up the application window; redirect stderr to /dev/null to ignore
//  various uninteresting messages.
$ x2goclient 2>/dev/null
```

Create and save the session parameters by starting a new session: 

   1. Session -> New Session
      *  Give the session a name
      *  Add the hostname or IP address
      *  Add your login name
      *  Check auto login
      *  Change 'Session type' to *MATE*
   2. Change tabs to the Input/Output tab
      *  Select a useful custom display geometry (e.g. Width: 1152 Height: 864)
   3. Change tabs to the Media tab
      *  Disable sound and client-side printing
   4. Click on the 'OK' button to save the session data
   5. Start the client connection by clicking on the session name on the right

If you are using X2Go between different Linux varieties you might need to
solve a few problems like font paths.

At the time of documenting this setup I found that starting the x2goclient
from an older Linux system like CentOS 7 to this Ubuntu system needed a tweak
in the Ubuntu Pi's sshd configuration in /etc/ssh/sshd_config; it was
fixed by adding 'PubkeyAcceptedAlgorithms +ssh-rsa'.  This was not needed
between similar Ubuntu setups.

[X2Go]: https://en.wikipedia.org/wiki/X2Go

<!-- Also describe startx? !! in a future client doc point out pkgs
      to install for traditional X fonts
  -->

