<!-- -->
# Creating a Samba file sharing service

We are going to create a Samba file sharing service on our server.  Other
devices like mobile phones, tablets, laptops and desktops running a variety
of operating systems should be able to manage files in the designated data
area.

We are not going to be really secure, in that we are allowing guest access.
Presumably if you let your family and your guests connect to your network,
then you would allow them to connect to your Samba server.

But as always, your internal home network should be well protected with at
least a strong password for your wireless SSID connections.

## Create the data space and assign appropriate permissions.

First, visit [Setting Up a Data Area](#data-area) in the appendix to find
out how to create your data area.

Always use a sub-directory inside the data area to begin any new project.
One of the advantages is that the [lost+found][lAf] directory does not become
part of your project.  For this Samba project we will create */data/shared*.

For Samba the top level ownership of the samba area will be a user
named 'nobody'.  This user is always created in Linux systems and
has no login shell, so 'nobody' cannot log in.  It is a safer user identity
to use for guest access to Samba shares.

We set the access permissions using chmod[^chmod] and chown[^chown].

```console
$ cd /data
$ sudo mkdir shared
$ sudo chown nobody:nogroup shared
$ sudo chmod g+ws shared
```

Here are 3 example directories to create for differing purposes:\
 'Music', 'Protected' and 'Test'\
other examples might be 'Videos' and 'Pictures':

You will be able to create directories inside the shared area using
your other devices as well.

I use the Test area initially for testing from various devices; that is,
create and delete files in the test directory.

```console
$ cd /data/shared
$ sudo mkdir Test
$ sudo chown nobody:nogroup Test
$ sudo chmod g+ws Test
```

I like having a general 'Protected' area that others can access but
cannot change.  I use secure-shell access to that area for dumping files
that I manage without using Samba tools.

```console
$ cd /data/shared
$ sudo mkdir Protected
$ sudo chown myname:mygroup Protected
$ sudo chmod g+ws Protected
```

As an example I put my old Music files in 'Music' so that it could be
accessed from various devices 24x7. You can either keep the permissions
as *nobody:nogroup*, allowing other people in your home network to help
manage the collection, or you can change ownership so that only you manage
them locally.  In this example my login name is 'myname' with group 'mygroup':

```console
$ du -sh /data/shared/Music/
7.4G    /data/shared/Music/
$ ls -la /data/shared/Music/
drwxr-sr-x  9 myname mygroup   4096 Apr 15 16:03 .
drwxrwsr-x  7 nobody nogroup   4096 Feb 26 11:59 ..
-rw-r--r--  1 myname mygroup 108364 Feb 27  2022 all.m3u
drwxr-xr-x  9 myname mygroup   4096 Feb 26  2022 Celtic
-rw-r--r--  1 myname mygroup  13373 Mar  6  2022 Celtic.m3u
...
drwxr-xr-x  5 myname mygroup   4096 Feb 27  2022 Nostalgia
-rw-r--r--  1 myname mygroup   6145 Feb 27  2022 Nostalgia.m3u
drwxr-xr-x 13 myname mygroup   4096 Feb 26  2022 Pop
-rw-r--r--  1 myname mygroup  10065 Feb 27  2022 Pop.m3u
drwxr-xr-x 39 myname mygroup   4096 Feb 26  2022 Rock
-rw-r--r--  1 myname mygroup  41656 Feb 27  2022 Rock.m3u
```

[chmod-help]: https://en.wikipedia.org/wiki/Chmod

[lAf]: https://www.baeldung.com/linux/lost-found-directory
[^chmod]: changes the mode of a file or directory. It takes
          [symbolic or numeric arguments][chmod-help].
[^chown]: changes the owner of a file or directory; with a colon it also
           changes the group ownership.

## Install the Samba software

Simply install the *samba* package; *apt* will pull in any dependencies:

```console
$ sudo apt install samba
...
0 upgraded, 21 newly installed, 0 to remove and 3 not upgraded.
Need to get 7,870 kB of archives.
After this operation, 44.1 MB of additional disk space will be used.
Do you want to continue? [Y/n] 
...
```

## Modify the Samba configuration file

The main configuration file is:\
 */etc/samba/smb.conf*

The file is organized into sections:

  * the *global* section
  * the *printers* section (which we will simply ignore, or you can
    comment it out)
  * any other **shares** that you create; in this example I create one
    named *home*

Here are the specifics:

  * Global Section
    1. In the global section change the *workgroup* name to something you
       like; I have chosen *LINUX*
    2. Just below the workgroup definition we add some [vfs_fruit][vfs]
       module options that allow Apple SMB clients to interact with the server
    3. we add a logging option to increase some logging for debugging
       purposes
  * Our 'share' section named *home*

The [modified smb.conf file][smb-conf] is in github.

```console
$ cd /etc/samba
$ sudo cp -p smb.conf smb.conf.orig
$ sudo nano smb.conf
// The 'diff' command shows differences in snippets with the line numbers
// A more elegant way to see the differences would be side-by-side:
//   diff --color=always -y smb.conf.orig smb.conf | less -r 
$ diff smb.conf.orig smb.conf
29c29,30
<    workgroup = WORKGROUP
---
> #   workgroup = WORKGROUP
>    workgroup = LINUX
33a35,39
> # for Apple SMB clients
>    fruit:nfs_aces = no
>    fruit:aapl = yes
>    vfs objects = catia fruit streams_xattr
> 
62a69,70
>    log level = 1 passdb:3 auth:3
> 
241a250,259
> 
> [home]
>     comment = Samba on Raspberry Pi
>     path = /data/shared
>     writable = yes
>     read only = no
>     browsable = yes
>     guest ok = yes
>     create mask = 0664
>     directory mask = 0775
```

[vfs]: https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html
[smb-conf]: https://raw.githubusercontent.com/deatrich/linux-home-server/main/examples/smb.conf

## Restart the service and check log files

```console
$ sudo systemctl restart smbd nmbd
$ systemctl status smbd | grep Status:
     Status: "smbd: ready to serve connections..."

$ systemctl  status nmbd | grep Status:
     Status: "nmbd: ready to serve connections..."

// 
$ cd /var/log/samba
$ ls -ltr
total 2168
drwx------ 5 root root    4096 May  7 09:45 cores/
-rw-r--r-- 1 root root     369 May  7 10:03 log.desktop
-rw-r--r-- 1 root root       0 May  7 10:08 log.ubuntu
-rw-r--r-- 1 root root    9000 May  7 10:51 log.192.168.1.82

$ tail log.192.168.1.82
[2023/05/07 10:51:01.059310,  3] ../../source3/auth/auth.c:201(auth_check_ntlm_password)
  check_ntlm_password:  Checking password for unmapped user ... with the new password interface
[2023/05/07 10:51:01.059391,  3] ../../source3/auth/auth.c:204(auth_check_ntlm_password)
  check_ntlm_password:  mapped user is: [LINUX]\[guest]@[UBUNTU]
```

## Run some tests

Tests to run to validate functionality include the following:

   1. Create a folder for your personal use
   2. Browse to the Test folder
   3. Copy and Paste a file from your device here
   4. Create a folder here too, and copy your file into that folder
   5. Delete all files and folders inside the Test folder

Testing will depend on your device and client.

*Suppose you have an Android phone*.  Download the App named
[Cx File Explorer][cx] from your App Store.  Under its *Network* tab
you can open a 'remote' Samba share in your home network.  You enter in
the IP address of the Pi server and select 'Anonymous' as the user
instead of user/pass.

(!! get an example from Windows and from an iphone)

*Suppose you have a MATE desktop session* on your Pi server or on another
Linux device.  Open a file browser:

  Applications -> Accessories -> Files

The Files browser 'File' menu has an option: *Connect to Server*.  If you
have an older version of Mate then find the help option and search for
 'Connect to Server'.

A small connection window pops up.  It is a bit annoying, so select any
options that allow the file browser to remember your entries, and also
create a bookmark.

There is no Samba password for 'guest', but the connection window will
want one anyway; so give it the password 'guest' to make it happy.

At this point an application named [seahorse][seahorse] might pop up.  It is
the GNOME encryption interface, and you can store passwords and keys in it.
I don't use it, but you might want to for this Samba share.
You can always cancel the seahorse window.

For the connection request, fill in this data:

  * Enter the IP address of your Pi server
  * Select 'Type' Windows share
  * Enter the share name:  home
  * Clear the Folder option
  * Enter the domain name: LINUX (or whatever name you chose in smb.conf)
  * User name: guest
  * Password: guest (and select the option to remember it for seahorse)
  * tick 'add bookmark' and give it a name

and finally connect.

[cx]: https://cxfileexplorer.com/
[seahorse]: https://wiki.gnome.org/Apps/Seahorse

