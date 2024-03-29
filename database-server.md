<!-- -->
# Creating a database server {#chapter-12}

Linux is a great platform for databases.  There are lots of options if
you want to dabble in database technology -- take a look at an example list of
[well-known open source database offerings][dbsoftware] on zenarmor.com.
Ubuntu packages and supports PostgreSQL, SQLite, MariaDB and Redis mentioned
on that list.

Here we are going to set up a MariaDB server.  MariaDB is a fork of MySQL,
well known as one of the four pillars of a
[LAMP (Linux, Apache, MySQL, PHP/Perl/Python)][lamp] Server.  Note that
Ubuntu also provides the MySQL offering that follows the Oracle MySQL
maintainers -- that package is named *mysql-server*.

[dbsoftware]: https://www.zenarmor.com/docs/linux-tutorials/best-open-source-database-software
[lamp]: https://en.wikipedia.org/wiki/LAMP_(software_bundle)

## Installing the server

The main package for a MariaDB server is *mariadb-server*.  It pulls in
additional support packages, including the client software used to query
the server databases.  Once up and running it listens on port 3306, which 
is defined in *mariadb.cnf*.  That file is found with other MySQL configuration
files residing in */etc/mysql/* on a Debian-based system.  Note that there
is also a file named *my.cnf* in the configuration area.  When
you install MariaDB the file 'my.cnf' is a symbolic link, pointing through
/etc/alternatives to 'mariadb.cnf'.

Some of the log files go to */var/log/mysql/* if you configure it in the
server configuration file.  Otherwise status logging shows up in
*/var/log/syslog*.

```console
$ sudo apt install mariadb-server
...
The following additional packages will be installed:
  galera-4 libcgi-fast-perl libcgi-pm-perl libconfig-inifiles-perl libdaxctl1
  libdbd-mysql-perl libfcgi-bin libfcgi-perl libfcgi0ldbl
  libhtml-template-perl libmariadb3 libmysqlclient21 libndctl6 libpmem1
  mariadb-client-10.6 mariadb-client-core-10.6 mariadb-common
  mariadb-server-10.6 mariadb-server-core-10.6 mysql-common socat
...
Setting up mariadb-server-10.6 (1:10.6.12-0ubuntu0.22.04.1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service ...
....

// The server by default listens on port 3306; here we see that only localhost
// is bound to that port in the lsof output.  Thus LAN nodes cannot connect:
$ sudo lsof -i :3306
COMMAND     PID  USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
mariadbd 709549 mysql   18u  IPv4 2506936      0t0  TCP localhost:mysql (LISTEN)

// The database files reside in '/var/lib/mysql/'
// That directory is protected, so you must use sudo to see it:
$ sudo ls -CpF /var/lib/mysql/
aria_log.00000001  ib_buffer_pool  multi-master.info    sys/
aria_log_control   ibdata1         mysql/
ddl_recovery.log   ib_logfile0     mysql_upgrade_info
debian-10.6.flag   ibtmp1          performance_schema/
```

## Configuring the server

The very first thing to do is secure the default configuration.   There is
a utility named *mysql_secure_installation* which helps you do this.
Note that the MySQL internal administrative user is also named *root* - this
is not the root user for the Linux operating system.

This utility allows you to do these things:

   * enforce 'unix_socket' authentication
   * set a password for the mysql 'root' user
   * remove the anonymous user
   * disable mysql root login from any other host
   * remove the test database, which allows anyone access to that database

The default answer is 'Y' to these questions; therefore if you hit the
carriage return you will get the defaults below:

```console
$ mysql_secure_installation
...
Switch to unix_socket authentication [Y/n]
Change the root password? [Y/n]
Remove anonymous users? [Y/n] 
Disallow root login remotely? [Y/n]
Remove test database and access to it? [Y/n] 
...
```

Since we set a mysql superuser ('root') password, then any user logged into
our server can connect as the mysql superuser if they know that password.
Otherwise, users with sudo privileges can connect without needing the password:

```console
$ mysql -u root
ERROR 1698 (28000): Access denied for user 'root'@'localhost'

// Use the '-p' option to get the password prompt:
$ mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
...

// Or use sudo to connect without the mysql superuser password:
// While we are at it, lets look at MySQL system variables to see what
// the storage engine defaults might be:
$ sudo mysql -u root
[sudo] password for myname: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 33
Server version: 10.6.12-MariaDB-0ubuntu0.22.04.1 Ubuntu 22.04
...
MariaDB> show variables like '%engine%';
+----------------------------+--------+
| Variable_name              | Value  |
+----------------------------+--------+
| default_storage_engine     | InnoDB |
| default_tmp_storage_engine |        |
| enforce_storage_engine     |        |
| gtid_pos_auto_engines      |        |
| storage_engine             | InnoDB |
+----------------------------+--------+
5 rows in set (0.004 sec)
MariaDB> show engines;
+--------------------+---------+---------------------------------------+--------------+-------+
| Engine             | Support | Comment                               | Transactions | XA ...|
+--------------------+---------+---------------------------------------+--------------+-------+
| CSV                | YES     | Stores tables as CSV files            | NO           | NO ...|
| MRG_MyISAM         | YES     | Collection of identical MyISAM tab... | NO           | NO ...|
| MEMORY             | YES     | Hash based, stored in memory, usef... | NO           | NO ...|
| Aria               | YES     | Crash-safe tables with MyISAM heri... | NO           | NO ...|
| MyISAM             | YES     | Non-transactional engine with good... | NO           | NO ...|
| SEQUENCE           | YES     | Generated tables filled with seque... | YES          | NO ...|
| InnoDB             | DEFAULT | Supports transactions, row-level l... | YES          | YES...|
| PERFORMANCE_SCHEMA | YES     | Performance Schema                    | NO           | NO ...|
+--------------------+---------+---------------------------------------+--------------+-------+

MariaDB> exit;
Bye
```

### Allowing non-superuser users to connect remotely

Most users who use MySQL databases interact with their own databases,
and do not need to touch the administrative server mysql databases.  So
it is reasonable to expect users to connect to the database from another
host.  Here we configure the Mariadb server to listen for LAN connections,
thus allowing users to connect via our home LAN:

```console
$ head /etc/mysql/mariadb.cnf
 # The MariaDB configuration file
 #
 # The MariaDB/MySQL tools read configuration files in the following order:
 # 0. "/etc/mysql/my.cnf" symlinks to this file, reason why all the rest is read.
 # 1. "/etc/mysql/mariadb.cnf" (this file) to set global defaults,
 # 2. "/etc/mysql/conf.d/*.cnf" to set global options.
 # 3. "/etc/mysql/mariadb.conf.d/*.cnf" to set MariaDB-only options.
 # 4. "~/.my.cnf" to set user-specific options.
...
$ cd /etc/mysql/mariadb.conf.d
$ sudo cp -p 50-server.cnf 50-server.cnf.orig
// Edit the server configuration, and change the 'bind-address' to 0.0.0.0
// Also enable separate error and slow-query logging:
$ sudo nano 50-server.cnf
$ diff 50-server.cnf.orig 50-server.cnf
27c27,28
< bind-address            = 127.0.0.1
---
> #bind-address            = 127.0.0.1
> bind-address            = 0.0.0.0
57c58
< #log_error = /var/log/mysql/error.log
---
> log_error = /var/log/mysql/error.log
59c60
< #slow_query_log_file    = /var/log/mysql/mariadb-slow.log
---
> slow_query_log_file    = /var/log/mysql/mariadb-slow.log
 
$ sudo systemctl restart mariadb
$ sudo lsof -i :3306
COMMAND     PID  USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
mariadbd 716168 mysql   18u  IPv4 2530211      0t0  TCP *:mysql (LISTEN)


// Though we can connect we are not allowed access until we create a regular
// database user:
$ mysql -u root -h pi.home -p
Enter password: 
ERROR 1130 (HY000): Host 'desktop.home' is not allowed to connect to this MariaDB server
```

So back on the database server let's create an empty database and two users
with LAN access to it.  One user is 'rw' (read-write) with all privileges
on its own database; the other user is 'ro' (read-only) with only select
privileges on its database.
In this example the LAN network is identified by all hosts in 192.168.1.

The default [MariaDB storage engine][storage-engines] is InnoDB; for this
exercise we will create a database named *webdb*.  Until you create
at least one table there is only a directory with a text options file
exists in the database area.  Thus the database engine is defined when tables
are created, not at database creation.

There is extensive help at the database prompt:

```console
$ sudo mysql -u root
...
MariaDB> help create database;
Name: 'CREATE DATABASE'
Description:
Syntax
------

CREATE [OR REPLACE] {DATABASE | SCHEMA} [IF NOT EXISTS] db_name
  [create_specification] ...
...
URL: https://mariadb.com/kb/en/create-database/

MariaDB> create database webdb;
...
MariaDB>  grant all privileges on webdb.* to 'rw'@'192.168.1.%'
    -> identified by 'some_password_here';

MariaDB> grant select on webdb.* to 'ro'@'192.168.1.%'
    -> identified by 'some_other_password_here';

MariaDB> flush privileges;
Query OK, 0 rows affected (0.002 sec)

MariaDB> select concat(user, '@', host) from mysql.global_priv;
+-------------------------+
| concat(user, '@', host) |
+-------------------------+
| ro@192.168.1.%          |
| rw@192.168.1.%          |
| mariadb.sys@localhost   |
| mysql@localhost         |
| root@localhost          |
+-------------------------+
5 rows in set (0.001 sec)

// Now I can connect to the database from my desktop:

$ mysql -u rw -h pi.home -p webdb
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
```

Now we add a simple table named *mytab* using the older MyISAM engine.
It is annoying to try to create a table interactively.  It is better to
create a small text file first.  So I create an sql file 'create_tab.sql',
and I source it at the database prompt:

```console
MariaDB> source create_tab.sql;
Query OK, 0 rows affected (0.02 sec)

MariaDB> show tables;
+-----------------+
| Tables_in_webdb |
+-----------------+
| members         |
+-----------------+
1 row in set (0.00 sec)

MariaDB> show create table members;
...
| members | CREATE TABLE `members` (
  `uid` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `moddate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `credate` timestamp NOT NULL DEFAULT current_timestamp(),
  `role` set('user','admin') NOT NULL DEFAULT 'user',
  `email` set('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci |
...

// And I insert a row into the table:
MariaDB> insert into members (email) values ('Y');
Query OK, 1 row affected (0.00 sec)

MariaDB> select * from members;
+-----+---------------------+---------------------+------+-------+
| uid | moddate             | credate             | role | email |
+-----+---------------------+---------------------+------+-------+
|   1 | 2023-06-30 16:09:29 | 2023-06-30 16:09:29 | user | Y     |
+-----+---------------------+---------------------+------+-------+
1 row in set (0.01 sec)

// Then I reconnect as the 'read-only' user.  I can select but nothing else:
$ mysql -u ro -h pi.home -p webdb
Enter password: 
Reading table information for completion of table and column names
...
MariaDB> select * from members;
+-----+---------------------+---------------------+------+-------+
| uid | moddate             | credate             | role | email |
+-----+---------------------+---------------------+------+-------+
|   1 | 2023-06-30 16:09:29 | 2023-06-30 16:09:29 | user | Y     |
+-----+---------------------+---------------------+------+-------+
1 row in set (0.00 sec)

MariaDB> delete from members;
ERROR 1142 (42000): DELETE command denied to user 'ro'@'desktop.home' for table `webdb`.`members`

$ sudo ls -l /var/lib/mysql/webdb/
-rw-rw---- 1 mysql mysql   67 Jun 30 15:10 db.opt
-rw-rw---- 1 mysql mysql 1050 Jun 30 16:09 members.frm
-rw-rw---- 1 mysql mysql   15 Jun 30 16:09 members.MYD
-rw-rw---- 1 mysql mysql 2048 Jun 30 16:09 members.MYI
```

[storage-engines]: https://mariadb.com/kb/en/storage-engines/


## Backing up a MariaDB database

Databases typically cannot be backed up reliably by backing up the filesystem
on which they live.  Minimally you would need to shut down the database to
get a copy of it using this method.

Instead, databases have some sort of export facility that locks and dumps
databases on demand, while also leaving the database up and running.  Databases
also need an import facility to re-create databases from the dump files.

For [MariaDB and MySQL][db-backups] *mysqldump* is used to export data,
while *mysqlimport* is used to re-create databases.

An [example mysql backup script][mysql-backup] in my github 'tools' area can
do local backups of the MariaDB database; it should be installed as
*/root/bin/mysql-backup.sh*.  It needs a
[configuration file][mysql-backup-conf] as well which must be installed as
*/etc/mysql-backup.conf*:

```console
// Edit the configuration file in case you want to use different directories:
$ sudo nano /etc/mysql-backup.conf

// Run the script in debug mode from the command line to make sure
// that everything is correctly configured:
$ sudo /root/bin/mysql-backup.sh --test

// Run the script once and check the log file for any errors:
$ sudo /root/bin/mysql-backup.sh

// Finally edit the cronjob to do daily database backups (here at 03h00):
$ EDITOR=/bin/nano sudo crontab -e
$ sudo crontab -l | grep mysql
0 3 * * * /root/bin/mysql-backup.sh
```

[db-backups]: https://www.digitalocean.com/community/tutorials/how-to-import-and-export-databases-in-mysql-or-mariadb
[mysql-backup-conf]: https://github.com/deatrich/tools/blob/main/etc/mysql-backup.conf
[mysql-backup]: https://github.com/deatrich/tools/blob/main/mysql-backup.sh

