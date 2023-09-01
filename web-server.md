<!-- -->
# Creating a web server {#web-server}

Setting up an [Apache][apache] web server is a great way to learn about
web technologies.  [Nginx][nginx] is another web server available on 
Ubuntu, but we will concentrate instead on the Apache offering.

We start with installing and doing an initial configuration of 
an http-based service listening on port 80.  Then we enable 
an https-based service listening on port 443.  Enabling https requires
setting up a certificate.  Since the web server is only in your home
network it is tricky to get an official web certificate.  Instead we will
create a self-signed certificate, and coax web clients to trust it.  Another
option is to build your own [certificate authority][certauth].

Finally we will look at configuring ownership of some of the Apache directory
infrastructure for future web projects and configuring a few virtual hosts.

[certauth]: https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04

## Installing and testing Apache 2.4

Install the Apache software. The ssl-cert package allows us to later
create an SSL certificate for the https service, so we will install it
as well.

```console
// The list of enabled apache modules on an Ubuntu system is also shown
// for your information:
$ sudo apt install apache2 ssl-cert
...
The following NEW packages will be installed:
  apache2 apache2-bin apache2-data apache2-utils libapr1 libaprutil1
  libaprutil1-dbd-sqlite3 libaprutil1-ldap liblua5.3-0
...
Setting up apache2 (2.4.52-1ubuntu4.5) ...
Enabling module mpm_event.
Enabling module authz_core.
Enabling module authz_host.
Enabling module authn_core.
Enabling module auth_basic.
Enabling module access_compat.
Enabling module authn_file.
Enabling module authz_user.
Enabling module alias.
Enabling module dir.
Enabling module autoindex.
Enabling module env.
Enabling module mime.
Enabling module negotiation.
Enabling module setenvif.
Enabling module filter.
Enabling module deflate.
Enabling module status.
Enabling module reqtimeout.
Enabling conf charset.
Enabling conf localized-error-pages.
Enabling conf other-vhosts-access-log.
Enabling conf security.
Enabling conf serve-cgi-bin.
Enabling site 000-default.
Created symlink /etc/systemd/system/multi-user.target.wants/apache2.service → ...
Created symlink /etc/systemd/system/multi-user.target.wants/apache-htcacheclean.service → ...
...
```

As always, systemd starts the daemon.  It is only listening on port 80 at this
point:

```console
$ sudo lsof -i :80
COMMAND    PID     USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
apache2 508647     root    4u  IPv6 1799685      0t0  TCP *:http (LISTEN)
apache2 508650 www-data    4u  IPv6 1799685      0t0  TCP *:http (LISTEN)
...
$ sudo lsof -i :443
```

We can open a web client (firefox for example) and look at the default web page.
We can also install a couple of useful *text-based* web clients which are
useful for doing quick checks:

```console
$ firefox http://pi.home/

$ sudo apt install links lynx
...
The following NEW packages will be installed:
  liblz1 links lynx lynx-common
...

$ links -dump http://pi.home/ | head
   Ubuntu Logo
   Apache2 Default Page
   It works!

   This is the default welcome page used to test the correct operation of the
   Apache2 server after installation on Ubuntu systems. ...

$ lynx --dump http://pi.home/ | head
   Ubuntu Logo
   Apache2 Default Page
   It works!
   ...
```

Log files for the Apache daemon are stored under */var/log/apache2/*:
```console
$ head /var/log/apache2/access.log
192.168.1.82 - -  ... "GET / HTTP/1.1" 200 3460 "-" "Mozilla/5.0 ... Firefox/113.0"
192.168.1.82 - -  ... "GET /icons/ubuntu-logo.png HTTP/1.1" 200 3607 "... Firefox/113.0"
192.168.1.82 - -  ... "GET /favicon.ico HTTP/1.1" 404 485 "http://pi.home/" ... Firefox/113.0"
192.168.1.100 - - ... "GET / HTTP/1.1" 200 3460 "-" "Links ... text)"
192.168.1.100 - - ... "GET / HTTP/1.0" 200 3423 "-" "Lynx/2.9.0dev.10 ... GNUTLS/3.7.1"
```

[apache]: https://ubuntu.com/server/docs/web-servers-apache
[nginx]: https://en.wikipedia.org/wiki/Nginx

## Generating a self-signed certificate and enabling HTTPS

Before we enable listening on port 443 we will generate a self-signed
SSL certificate.  I have a script named [*addcert.sh*][addcert.sh]
which will generate the needed certificate files.  You need to use
a configuration file named [*addcert.cnf*][addcert.cnf] and edit it 
to use your certificate details:

```console
$ mkdir ~/certs
$ cd ~/certs
$ cp /path/to/addcert.cnf .
$ cp /path/to/addcert.sh ~/bin/
$ chmod 755 ~/bin/addcert.sh
$ nano addcert.cnf
$ ~/bin/addcert.sh
Certificate request self-signature ok
subject=C = CA, ST = British Columbia, ... CN = pi.home, emailAddress = some.email@somewhere.com
-r--r--r-- 1 myname myname 2000 Jun 21 10:00 server.crt
-r--r--r-- 1 myname myname 1740 Jun 21 10:00 server.csr
-r-------- 1 myname myname 3272 Jun 21 10:00 server.key
addcert.sh:  SVP copy server files into place and change ownership to root

// You can query the text version of your certificate:
$ openssl x509 -in server.crt -text | less
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number:
            70:5b:1d:...
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = CA, ST = British Columbia, L = Cranbrook, O = Home ...
        ...
            Not Before: Jun 21 16:00:37 2023 GMT
            Not After : Jun 18 16:00:37 2033 GMT
        ...
```

The server key file and the server key certificate need to be copied into
the Apache configuration area, and the ssl configuration paths need to be
updated:

```console
$ cd /etc/apache2
$ sudo mkdir certs
$ cd /home/myname/certs/
$ sudo cp -pi server.key server.crt /etc/apache2/certs/
$ cd /etc/apache2/certs
$ sudo chown root:root server.key server.crt
$ ls -l
-r--r--r-- 1 root root 2000 Jun 21 10:00 server.crt
-r-------- 1 root root 3272 Jun 21 10:00 server.key
```
 
Now we enable SSL in apache, using a utility named *a2enmod*.  We also
enable the SSL default configuration using the utility *a2ensite*.  We
need to edit the configuration file with our path to the certificate and
key files.  Once we have done that we can restart apache.

```console
// enable the module:
$ sudo a2enmod ssl
Considering dependency setenvif for ssl:
Module setenvif already enabled
Considering dependency mime for ssl:
Module mime already enabled
Considering dependency socache_shmcb for ssl:
Enabling module socache_shmcb.
Enabling module ssl.
See /usr/share/doc/apache2/README.Debian.gz on how to ... and create self-signed certificates.
...

// enable the SSL configuration as a virtual host:
$ sudo a2ensite default-ssl
Enabling site default-ssl.
...

// Listing the enabled configuration files shows the following:
$ pwd
/etc/apache2/
$ ls -l sites-enabled/
lrwxrwxrwx ... Jun 19 10:47 000-default.conf -> ../sites-available/000-default.conf
lrwxrwxrwx ... Jun 21 10:19 default-ssl.conf -> ../sites-available/default-ssl.conf

// So we can edit '/etc/apache2/sites-available/default-ssl.conf'
$ cd /etc/apache2/sites-available
$ sudo cp -p default-ssl.conf default-ssl.conf.orig
$ sudo nano default-ssl.conf
$ diff default-ssl.conf.orig default-ssl.conf
32,33c32,33
<               SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
<               SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
---
>               SSLCertificateFile      /etc/apache2/certs/server.crt
>               SSLCertificateKeyFile   /etc/apache2/certs/server.key

$ sudo systemctl restart apache2
$ sudo lsof -i | grep apache
apache2  549190         root   4u  IPv6 1943852      0t0  TCP *:http (LISTEN)
apache2  549190         root   6u  IPv6 1943856      0t0  TCP *:https (LISTEN)
apache2  549191     www-data   4u  IPv6 1943852      0t0  TCP *:http (LISTEN)
apache2  549191     www-data   6u  IPv6 1943856      0t0  TCP *:https (LISTEN)
apache2  549192     www-data   4u  IPv6 1943852      0t0  TCP *:http (LISTEN)
apache2  549192     www-data   6u  IPv6 1943856      0t0  TCP *:https (LISTEN)
```

Now we want to test the secured web connection connection, and 
ask your web browser to accept the certificate. With *firefox* we 
select 'Advanced' where we see the message\

 *Error code: MOZILLA_PKIX_ERROR_SELF_SIGNED_CERT*

We go ahead and accept the risk and we see our default secured web page.
You only need to do this once.

Both text mode browsers will warn about self-signed certificates, but
also will allow you to connect:

```console
$ firefox https://pi.home

// This example is with 'links' -- we ignore self-signed certs when we use 
// the '-ssl.certicates 0' option
$ links -dump -ssl.certificates 0  http://pi.home/ | head
   Ubuntu Logo
   Apache2 Default Page
   It works!

   This is the default welcome page used to test ...
```

[addcert.sh]: https://github.com/deatrich/tools/blob/main/addcert.sh
[addcert.cnf]: https://github.com/deatrich/tools/blob/main/etc/addcert.cnf

## Apache directory infrastructure

When developing web infrastructure and editing web pages you should always
work as a regular user, and never as root.  The best way to proceed is to
assign ownership of specific directories in the web tree to regular users
like yourself.

One way to do this is to simply change the ownership of /var/www/html/
to yourself -- this will also change ownership for any files in the directory.
This way you can immediately add and change content as a regular user.

```console
$ cd /var/www/html
$ sudo chown -R myname:myname .
```

Another way to do this is to make sub-directories inside /var/www/html/ and
assign ownership of them to yourself.  Then you add your own site configuration
file(s) in */etc/apache2/sites-available/* with your new sub-directory path(s)
and enable them.

```console
// Make a couple of subdirectories and assign them to yourself.  Suppose
// you want to use http-served pages for development under /var/www/html/test/,
// and use https-served pages for production under /var/www/html/pi/.
// We also copy the existing 'index.html' file to each sub-directory as a
// quick test:
$ cd /var/www/html
$ sudo mkdir test pi
$ sudo cp -p /var/www/html/index.html test/
$ sudo cp -p /var/www/html/index.html pi/
$ sudo chown -R myname:myname test pi

// Let's change the 'title' description in both 'index.html' files so that
// we see the difference in testing:
$ nano pi/index.html
$ nano test/index.html
$ grep 'title' pi/index.html test/index.html
pi/index.html:    <title>Apache2 Ubuntu Default Page on HTTPS (secure): It works</title>
test/index.html:    <title>Apache2 Ubuntu Default Page on HTTP (no encryption): It works</title>

// Create a configuration file based on the existing configurations:
$ cd /etc/apache2/sites-available
$ sudo cp -p 000-default.conf test.conf

// Change the DocumentRoot, and also change the log files names for this site:
$ sudo nano test.conf
$ diff 000-default.conf test.conf 
12c12
<       DocumentRoot /var/www/html
---
>       DocumentRoot /var/www/html/test
20,21c20,21
<       ErrorLog ${APACHE_LOG_DIR}/error.log
<       CustomLog ${APACHE_LOG_DIR}/access.log combined
---
>       ErrorLog ${APACHE_LOG_DIR}/test-error.log
>       CustomLog ${APACHE_LOG_DIR}/test-access.log combined

$ sudo cp -p default-ssl.conf pi.conf

// Again, change the DocumentRoot, and change the log files names for this site:
$ sudo nano pi.conf
$ diff default-ssl.conf pi.conf 
5c5
<               DocumentRoot /var/www/html
---
>               DocumentRoot /var/www/html/pi
13,14c13,14
<               ErrorLog ${APACHE_LOG_DIR}/error.log
<               CustomLog ${APACHE_LOG_DIR}/access.log combined
---
>               ErrorLog ${APACHE_LOG_DIR}/pi-error.log
>               CustomLog ${APACHE_LOG_DIR}/pi-access.log combined

// Finally enable the new site configurations, and disable the old ones;
// then restart apache:
$ sudo a2ensite test
Enabling site test.
...
$ sudo a2ensite pi
Enabling site pi.
...
$ sudo a2dissite 000-default default-ssl
Site 000-default disabled.
Site default-ssl disabled.
...
$ ls -l /etc/apache2/sites-enabled/
total 0
lrwxrwxrwx 1 root root 26 Jun 22 14:11 pi.conf -> ../sites-available/pi.conf
lrwxrwxrwx 1 root root 28 Jun 22 14:11 test.conf -> ../sites-available/test.conf
$ sudo systemctl restart apache2
$ systemctl status apache2
     ...
     Active: active (running) since Thu 2023-06-22 14:14:00 MDT; 2s ago
     ...
```

Now test the changed configurations using *links* and the '-source' argument:

```console
$ links -source http://pi.home/ | grep title
    <title>Apache2 Ubuntu Default Page on HTTP (no encryption): It works</title>

$ links -source -ssl.certificates 0 https://pi.home/ | grep title
    <title>Apache2 Ubuntu Default Page on HTTPS (secure): It works</title>
```

Also, you can always add new sub-directories for web page design,
rather than changing ownership inside /var/www/html.  For example,
create a sub-directory owned by yourself named /var/www/sites and add your
own site configuration in */etc/apache2/sites-available/* with your new
sub-directory path(s) and enable them.  The exercise is very similar to the
previous example.

## Apache configuration issues

For home use the default settings in */etc/apache2/apache2.conf* are fine.
However these settings are too open in my opinion, and I would never keep
such a configuration on a publicly-exposed web server.

Be aware of these settings if you plan on using home-grown configurations
on an internet-exposed site:

   * The configuration for the root of the file system allows *FollowSymLinks*
   * Access to directory */usr/share* is allowed
   * The base of the web tree, */var/www/*, allows *Indexes* and
     *FollowSymLinks* -- these settings should be enabled only within site
     configurations for specific sub-directories on an as-needed basis

When you work on internet-exposed sites you should generally learn enough
about Apache configurations to cope with installing new packages and 
safely configuring them, without depending on deliberately loose initial
configurations that shield you from necessary details.

## Disabling IPv6 access to the Apache daemon

If you want to configure Apache to listen only for IPv4 connections, then
alter */etc/apache2/ports.conf* and change instances of *Listen PORTNUMBER*
to *Listen 0.0.0.0:PORTNUMBER*.  You will also need to change site
configuration *VirtualHost* settings to use *0.0.0.0:PORTNUMBER*.  By using
'0.0.0.0' all hardware network interfaces on your machine would serve web
pages.  On SBC hardware that is not an issue; on complex hardware with
multiple network interfaces on differing networks this would not necessarily
be what you wanted - in that case a specific IP address is used instead.

```console
$ cd /etc/apache2
$ diff ports.conf.orig ports.conf
5c5
< Listen 80
---
> Listen 0.0.0.0:80
8c8
<       Listen 443
---
>       Listen 0.0.0.0:443
12c12
<       Listen 443
---
>       Listen 0.0.0.0:443

$ diff sites-available/000-default.conf.orig sites-available/000-default.conf
1c1
< <VirtualHost *:80>
---
> <VirtualHost 0.0.0.0:80>
10a11,12
>       ServerName pi.home
>       ServerAlias pi
12c14,20
<       DocumentRoot /var/www/html
---
>       DocumentRoot /var/www/html/test
...

$ diff sites-available/default-ssl.conf.orig sites-available/default-ssl.conf
2c2
<       <VirtualHost _default_:443>
---
>       <VirtualHost 0.0.0.0:443>
...
```

## Installing the PHP Apache module

If you are interesting in doing some embedded PHP web development then
you only need to install the PHP Apache module:

```console
$ sudo apt install libapache2-mod-php
 ...
The following additional packages will be installed:
  libapache2-mod-php8.1 php-common php8.1-cli php8.1-common php8.1-opcache
  php8.1-readline
 ...
Unpacking libapache2-mod-php (2:8.1+92ubuntu1) ...
Setting up php-common (2:92ubuntu1) ...
Created symlink /etc/systemd/system/timers.target.wants/phpsessionclean.timer ...
 ...
Setting up libapache2-mod-php8.1 (8.1.2-1ubuntu2.11) ...
apache2_invoke: Enable module php8.1
Setting up libapache2-mod-php (2:8.1+92ubuntu1) ...
 ...

// the PHP module is already enabled:
$ cd /etc/apache2/
$ find . -iname \*php\*
./mods-available/php8.1.conf
./mods-available/php8.1.load
./mods-enabled/php8.1.conf
./mods-enabled/php8.1.load
```

You can quickly test that PHP works; simply create a PHP file in the root of
your new web tree and point your browser to it:

```console
// Here we assume that the root of your web tree is at /var/www/html/test/
$ cd /var/www/html/test/
$ echo "<?php phpinfo() ?>" > info.php

// now use either 'firefox' or 'links' to look at it:
$ firefox http://pi.home/info.php

$ links -dump http://pi.home/info.php | head
   PHP logo

   PHP Version 8.1.2-1ubuntu2.11

   System            Linux pi.home 5.15.0-1029-raspi #31-Ubuntu SMP PREEMPT
                     Sat Apr 22 12:26:40 UTC 2023 aarch64
   Build Date        Feb 22 2023 22:56:18
   Build System      Linux
   Server API        Apache 2.0 Handler
 ...

// The PHP function 'phpinfo()' shows all configuration information that
// you as a developer want to know about.  However, do not expose all this
// information to others in a publicly available web site.  Remove the 
// info.php file after use, or hide it from the apache daemon:
$ cd /var/www/html/test/
$ rm info.php
// or set it read-write to yourself only:
$ chmod 600 info.php
```

You might want to disable PHP session cleanup until a later time
when you are actually making use of PHP sessions.  You can re-enable this
later when you think you need it:

```console
$ systemctl list-unit-files | grep php
phpsessionclean.service                    static          -
phpsessionclean.timer                      enabled         enabled

$ sudo systemctl mask phpsessionclean.timer
Created symlink /etc/systemd/system/phpsessionclean.timer → /dev/null.

$ tail -1 /etc/cron.d/php
09,39 *     * * *     root   [ -x /usr/lib/php/sessionclean ] && if ...

// This is an example case of not making a copy of a file in the same directory.
// All valid files in '/etc/cron.d/' are subject to being run by the 'cron'
// daemon.  Instead we put a copy in root's home directory, in case we need it
// as a reference:
$ sudo cp -p /etc/cron.d/php /root/php.orig

// When we edit this cron file we comment out the active entry with a '#':
$ sudo nano /etc/cron.d/php
$ sudo diff /root/php.orig /etc/cron.d/php
14c14
< 09,39 *     * * *     root   [ -x /usr/lib/php/sessionclean ] && if ...
---
> #09,39 *     * * *     root   [ -x /usr/lib/php/sessionclean ] && if ...
```

<!-- !! need to add logging information -->
