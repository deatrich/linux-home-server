<!-- -->
# Enabling the Secure Shell Daemon and Using Secure Shell {#sshd}

The [Secure Shell][secure-shell] daemon, ***sshd***, is a very useful and
important service for connecting between computers near or far.  If you
are never going to connect via SSH into your Pi home server from
within your network then do NOT install the daemon.  You can always
use the secure shell client, ***ssh***, to initiate a connection
to some external server -- for that you do not need sshd.

## Configure the sshd Daemon

If you will be needing sshd then first install it, since
it is not installed by default in the LTS desktop version:

~~~~ {.shell}
$ sudo apt install openssh-server
~~~~

If you will be using ssh to connect to any local Linux systems, then
think about configuring your local area network (LAN) to suit your taste.
There is an [explanation in the appendix](#lan).

There are some sshd configuration issues that I like to fix in the secure shell
daemon's configuration file: */etc/ssh/sshd_config*.  The issues to fix are:

  * stop the daemon from listening on IPv6: *AddressFamily inet*
  * tell the daemon to use DNS: *UseDNS yes*
  * limit ssh access to yourself in your LAN; and block ssh access\
     to the root user except for 'localhost':\
      AllowUsers    myname@192.168.1.\* \*@localhost*

~~~~ {.shell}
$ cd /etc/ssh
$ sudo cp -p sshd_config sshd_config.orig

// edit the file:
$ sudo nano sshd_config

$ diff sshd_config.orig sshd_config
15a16
> AddressFamily inet
101a103
> UseDNS yes
122a125,130
> 
> # Limit access to root user; only local users can connect via ssh
> # to root only if root's authorized_keys file allows them.
> # note: using @localhost does not work on ubuntu unless you set UseDNS to yes
> AllowUsers    myname@192.168.1.* *@localhost
> 

// Another option is to also allow root access to this server from your Linux
// desktop (eg: 192.168.1.65).  Then the 'AllowUsers' configuration would
// look like this:
AllowUsers      myname@192.168.1.* root@192.168.1.65 *@localhost
~~~~

## Configure a Personal SSH Key Pair {#key-pair}

If you use the Linux command-line for work between computers you soon 
understand the usefulness of ssh.  Here we go through the exercise of
creating an ssh key pair so that you can connect securely between devices.

We use *ssh-keygen* to create the key pair.  You should treat the private
key carefully, distributing it to your desktop systems only.  You can copy
your public key to remote hosts, where you create an *authorized_keys* file
that specifies which public keys are allowed to connect without using a
standard system password.

Over time the Secure Shell key types have changed.  Some key types are no
longer considered secure, like SSH-1 or DSA keys.  Here we will use an SSH
RSA-based key with a key size of 4096 bits.  Always use a strong passphrase.
It is not like a password since you have more liberty to use combinations of
characters; as the man-page on ssh-keygen says:

>  A passphrase is similar to a password, except it can be a phrase with a
>  series of words, punctuation, numbers, whitespace, or any string of
>  characters you want.

I would not create a passphrase that is less than 16 characters; I would
certainly never set an empty passphrase.

~~~~ {.shell}
// If you do not yet have a .ssh directory in your home directory then
// create one now; and give access to yourself only:

$ cd
$ mkdir .ssh
$ chmod 700 .ssh

// Generate the key:
$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/home/myname/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/myname/.ssh/id_rsa.

// The private key is named 'id_rsa' and the public key is named 'id_rsa.pub'
// Note the permissions of these 2 files; the private key is protected
// and is read-write only to the owner.
$ ls -l ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
-rw------- 1 myname myname 3326 May  2 22:34 /home/myname/.ssh/id_rsa
-rw-r--r-- 1 myname myname  746 May  2 22:34 /home/myname/.ssh/id_rsa.pub
~~~~

Be sure to back-up important directories like $HOME/.ssh -- in your home
environment it might not seem important, but once you start using your ssh
keys for access to external resources then you should follow good practices.
If you lose the private key then you will need to generate a new key pair.

Suppose you created your keys on your desktop, and you want to use them
to ssh to your Linux home server without using a standard password.  To
do this you create an authorized keys file on the server:

~~~~ {.shell}
// secure-copy your public key to the linux server (assuming the server is
named 'pi')
$ scp ~/.ssh/id_rsa.pub myname@pi:~/
The authenticity of host 'pi (192.168.1.90)' can't be established.
ECDSA key fingerprint is SHA256:iP...
ECDSA key fingerprint is MD5:79:54:...
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'pi,192.168.1.90' (ECDSA) to the list of known hosts.

// On the server create your authorized_keys file if it does not exist
// inside '~/.ssh', and then 'cat' your public key to the end of the file.
// The authorized_keys file should always be protected.

$ ssh myname@pi
myname@pi's password:
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
$ cd ~/.ssh
$ touch authorized_keys
$ chmod 600 authorized_keys
$ cat /path/to/id_rsa.pub >> authorized_keys
$ tail -1 authorized_keys
ssh-rsa AAAAB3...6oLYnLx5d myname@somewhere.com
$ rm /path/to/id_rsa.pub
// logout from the server session
$ exit

// Back on the desktop verify that you can ssh into the server using only
// the key's passphrase (and not your password):
$ ssh myname@pi
Enter passphrase for key '/home/myname/.ssh/id_rsa': 
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-1027-raspi aarch64)
...
$ exit

// If you want to only allow ssh access to your account from a specific
// computer in your LAN, than limit the hosts which are allowed by using
// the 'from=' option.  Edit the authorized_keys file and prepend the 
// 'from=' option like this:
$ pwd
/home/myname/.ssh
// allow from host with IP address 192.168.1.65, and from localhost:
$ nano authorized_keys
$ tail -1 authorized_keys
from="192.168.1.65" ssh-rsa AAAAB3...6oLYnLx5d myname@somewhere.com
~~~~

## Configure an SSH agent

The goal here is to start an [SSH agent][ssh-agent] on your desktop, and add
your key(s) to the agent.

With a few tweaks we allow other programs to inherit the ssh-agent
*environment variables* and we avoid entering passwords
and passphrases throughout the day, or until you logout, reboot or turn off
your desktop.

#### Script to start an ssh-agent

Download the shell script named [*prime-ssh-keys.sh*][prime-ssh-keys.sh]
to start the agent. The script saves the environment variables in a file named:

> ~/.ssh-agent-info-YOUR-FULL-HOSTNAME

~~~~ {.shell}
// Copy the shell script to your home 'bin' directory; create it if needed:
$ cd
$ mkdir bin
$ cp /path/to/prime-ssh-keys.sh ~/bin/
$ chmod 755 ~/bin/prime-ssh-keys.sh 

// Run the script:
$ ~/bin/prime-ssh-keys.sh 
Enter passphrase for /home/myname/.ssh/id_rsa: 
Identity added: /home/myname/.ssh/id_rsa (/home/myname/.ssh/id_rsa)
 
// This file sets and exports environment variables for the socket and the PID:
$ cat ~/.ssh-agent-info-desktop.home
SSH_AUTH_SOCK=/tmp/ssh-XXXXXXxRlqsm/agent.21324; export SSH_AUTH_SOCK;
SSH_AGENT_PID=21325; export SSH_AGENT_PID;

// Now if you 'source' the agent file to inherit the environment variables
//  you will be able to ssh into the linux server without using
//  a password or passphrase:
$ . ~/.ssh-agent-info-desktop.home 
$ ssh -Y pi.home
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-1027-raspi aarch64)
...
Last login: Thu May 11 23:56:17 2023 from desktop.home
$ 
~~~~

#### Script to start an ssh-agent at initial login

In a MATE desktop setting, you can add startup programs that run as 
soon as you log into your desktop.  You can find the startup options
in:

>  Menus -> System -> Preferences -> Personal -> Startup Applications

Create and add the script -- it will open a temporary terminal
window asking for the passphrase(s) for your key(s).  The terminal
window can be any terminal the allows you to run a shell script as
an argument.  You can use *mate-terminal*, or if you have installed the
**xterm** package then you can use *xterm*.  Note that the
script invokes a shell (*/bin/sh* is a symbolic link to */bin/bash*, and
starts with a [shebang][shebang])

~~~~ {.shell}
// make the 'bin' directory if it does not exist:
$ cd
$ touch ~/bin/exec-prime-ssh-keys.sh
$ chmod 755 ~/bin/exec-prime-ssh-keys.sh
$ nano ~/bin/exec-prime-ssh-keys.sh
$ cat ~/bin/exec-prime-ssh-keys.sh
#!/bin/sh

#Decide which terminal command you will use:
exec mate-terminal -e /home/myname/bin/prime-ssh-keys.sh & 2>/dev/null
#exec xterm -u8 -e /home/myname/bin/prime-ssh-keys.sh & 2>/dev/null
~~~~

Another useful tactic is to get your personal bash shell configuration
file to inherit the SSH agent's environment variables.  Create a small
script named *~/.bash_ssh_env*  which provides the variables.  You can
process that file in your *~/.bashrc* file so that any new terminal window
you launch will always inherit the variables.  As well, other scripts which
might need the variables can do the same.

~~~~ {.shell}
// First create .bash_ssh_env; we 'cat' it after to show what it contains:
$ nano ~/.bash_ssh_env
$ cat ~/.bash_ssh_env

ssh_info_file=$HOME/.ssh-agent-info-`/usr/bin/hostname`
if [ -f $ssh_info_file ] ; then
  . $ssh_info_file
fi

// Then source ~/.bash_ssh_env inside your .bashrc file by simply including
// the following line in ~/.bashrc:

. ~/.bash_ssh_env
~~~~

[secure-shell]: https://en.wikipedia.org/wiki/Secure_Shell
[ssh-agent]: https://www.ssh.com/academy/ssh/agent
[prime-ssh-keys.sh]: https://github.com/deatrich/tools/blob/main/prime-ssh-keys.sh
[shebang]: https://en.wikipedia.org/wiki/Shebang_(Unix)

## Personal Configuration in 'config' File

You can configure some personal preferences in a configuration file named
*$HOME/.ssh/config* 

I have a few favourite settings which have solved issues I have encountered
in the past (like setting *KeepAlive* and *ServerAliveInterval*).  A new
favourite is setting **HashKnownHosts** to *no*.  I like seeing the name of
hosts I have connected to in ~/.ssh/known_hosts.  Debian/Ubuntu set globally
the *HashKnownHosts* value to *yes*.  The result is that you can no longer
seeing hostnames or IP addresses in your known_hosts file because they have
been 'hashed'.`

This is also where you can assign customized per-host ssh key pair filenames
to particular hosts.

~~~~ {.shell}
// Create and edit your ssh config file:
$ cd ~/.ssh/
$ touch config
$ chmod 600 config
$ nano config 
$ cat config 
## see:  man ssh_config

## ssh configuration data is parsed in the following order:
##         1.   command-line options
##         2.   user's configuration file (~/.ssh/config)
##         3.   system-wide configuration file (/etc/ssh/ssh_config)
## Any configuration value is only changed the first time it is seen.
## Therefore this file overrides system-wide defaults.

Host *
   KeepAlive yes
   ServerAliveInterval 60
   HashKnownHosts no

## Example private key which has a customized key name for github.com
Host github.com
   IdentityFile ~/.ssh/id_rsa_github
~~~~
