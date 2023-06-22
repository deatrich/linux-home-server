<!-- -->
# Creating a Web Server

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

Finally we will look at configuring ownership of some of the apache directory
infrastructure for future web projects and configuring a few virtual hosts.

[certauth]: https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04

## Installing and Testing Apache 2.4

Install the apache software. The ssl-cert package allows us to later
create an SSL certificate for the https service, so we will install it
as well.

~~~~ {.shell}
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
~~~~

As always, systemd starts the daemon.  It is only listening on port 80 at this
point:

~~~~ {.shell}
$ sudo lsof -i :80
COMMAND    PID     USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
apache2 508647     root    4u  IPv6 1799685      0t0  TCP *:http (LISTEN)
apache2 508650 www-data    4u  IPv6 1799685      0t0  TCP *:http (LISTEN)
...
$ sudo lsof -i :443

~~~~

We can open a web client and look at the default web page with a web client --
firefox for example.  We can also install a couple of useful *text-based*
web clients which are useful for doing quick checks:

~~~~ {.shell}
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
~~~~

[apache]: https://ubuntu.com/server/docs/web-servers-apache
[nginx]: https://en.wikipedia.org/wiki/Nginx

## Generating a Self-Signed Certificate and Enabling https

Before we enable listening on port 443 we will generate a self-signed
SSL certificate.  I have a script named [*addcert.sh*][addcert.sh]
which will generate the needed certificate files.  You need to use
a configuration file named [*addcert.cnf*][addcert.cnf] and edit it 
to use your certificate details:

~~~~ {.shell}
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
~~~~

The server key file and the server key certificate need to be copied into
the apache configuration area, and the ssl configuration paths need to be
updated:

~~~~ {.shell}
$ cd /etc/apache2
$ sudo mkdir certs
$ cd /home/myname/certs/
$ sudo cp -pi server.key server.crt /etc/apache2/certs/
$ cd /etc/apache2/certs
$ sudo chown root:root server.key server.crt
$ ls -l
-r--r--r-- 1 root root 2000 Jun 21 10:00 server.crt
-r-------- 1 root root 3272 Jun 21 10:00 server.key
~~~~
 
Now we enable SSL in apache, using a utility named *a2enmod*.  We also
enable the SSL default configuration using the utility *a2ensite*.  We
need to edit the configuration file with our path to the certificate and
key files.  Once we have done that we can restart apache.

~~~~ {.shell}
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
To activate the new configuration, you need to run:
  systemctl restart apache2

// enable the SSL configuration as a virtual host:
$ sudo a2ensite default-ssl
Enabling site default-ssl.
To activate the new configuration, you need to run:
  systemctl reload apache2

// Listing the enabled configuration files shows the following:
$ pwd
/etc/apache2/
$ ls -l sites-enabled/
lrwxrwxrwx ... Jun 19 10:47 000-default.conf -> ../sites-available/000-default.conf
lrwxrwxrwx ... Jun 21 10:19 default-ssl.conf -> ../sites-available/default-ssl.conf

// So we can edit /etc/apache2/sites-available/default-ssl.conf
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
~~~~

Now we want to test the secured web connection connection, and 
ask your web browser to accept the certificate. With *firefox* we 
select 'Advanced' where we see the message\

 *Error code: MOZILLA_PKIX_ERROR_SELF_SIGNED_CERT*

We go ahead and accept the risk and we see our default secured web page.
You only need to do this once.

Both text mode browsers will warn about self-signed certificates, but
also will allow you to connect:

~~~~ {.shell}
$ firefox https://pi.home

// This example is with 'links' -- we ignore self-signed certs with 
// the '-ssl.certicates 0' option
$ links -dump -ssl.certificates 0  http://pi.home/ | head
   Ubuntu Logo
   Apache2 Default Page
   It works!

   This is the default welcome page used to test ...
~~~~

[addcert.sh]: https://github.com/deatrich/tools/blob/main/addcert.sh
[addcert.cnf]: https://github.com/deatrich/tools/blob/main/etc/addcert.cnf

## Apache Directory Infrastructure

When developing web infrastructure and editing web pages you should always
work as a regular user, and never as root.  The best way to proceed is to
assign ownership of specific directories in the web tree to regular users
like yourself.

One way to do this is to simply change the ownership of /var/www/html/
to yourself -- this will also change ownership for any files in the directory.
This way you can immediately add and change content as a regular user.

~~~~ {.shell}
$ cd /var/www/html
$ sudo chown -R myname:myname .
~~~~

Another way to do this is to make sub-directories inside /var/www/html/ and
assign ownership of them to yourself.  Then you add your own site configuration
file(s) in */etc/apache2/sites-available/* with your new sub-directory path(s)
and enable them.

~~~~ {.shell}
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

// Change the DocumentRoot, and also change the log files names:
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

// Again, change the DocumentRoot, and also change the log files names:
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
To activate the new configuration, you need to run:
  systemctl reload apache2
$ sudo a2ensite pi
Enabling site pi.
To activate the new configuration, you need to run:
  systemctl reload apache2

$ sudo a2dissite 000-default default-ssl
Site 000-default disabled.
Site default-ssl disabled.
To activate the new configuration, you need to run:
  systemctl reload apache2
$ ls -l /etc/apache2/sites-enabled/
total 0
lrwxrwxrwx 1 root root 26 Jun 22 14:11 pi.conf -> ../sites-available/pi.conf
lrwxrwxrwx 1 root root 28 Jun 22 14:11 test.conf -> ../sites-available/test.conf
$ sudo systemctl restart apache2
$ systemctl status apache2
     ...
     Active: active (running) since Thu 2023-06-22 14:14:00 MDT; 2s ago
     ...
~~~~

Now test the changed configurations using *links* and the '-source' argument:

~~~~ {.shell}
$ links -source http://pi.home/ | grep title
    <title>Apache2 Ubuntu Default Page on HTTP (no encryption): It works</title>

$ links -source -ssl.certificates 0 https://pi.home/ | grep title
    <title>Apache2 Ubuntu Default Page on HTTPS (secure): It works</title>
~~~~

Also, you can always add new sub-directories for web page design,
rather than changing ownership inside /var/www/html.  For example,
create a sub-directory owned by yourself named /var/www/sites and add your
own site configuration in */etc/apache2/sites-available/* with your new
sub-directory path(s) and enable them.  The exercise is very similar to the
previous example.

<!-- !! need to add logging information -->
<!-- !! need to add a warning note about the 'include' options in the
        apache main configuration file -->
<!--
~~~~ {.shell}
~~~~
 -->
