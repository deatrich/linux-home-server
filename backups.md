<!-- -->
# Backing up Your Server

Always, always, do some kind of backups on your server.  For
system backups, very little actually needs to be backed up, yet it is
important to get into a frame of mind where you think about these things.
Lets look at what you should back up on your server, and how you might do it.

There is no need to back up everything - you can always reinstall and 
reconfigure.  This is my favourite list of system directories to back up:

  * /etc  -- a lot of system configuration is in this directory.  Some
             important configuration files found here are: the host's
             secure-shell keys, user account details, and most server
             configuration changes
  * /home    -- this is where your user account resides
  * /root    -- this is the superuser's home directory
  * /var/log -- system log files are here; for forensic reasons I back them up
  * /var/spool -- in case you have personalized cron job entries
  * /var/www -- if you have a web server then it's data files are usually here

If you are playing with database services then you need to inform yourself
which directories and/or data exports should be added and/or used for backups.
Note that when you have create a Samba or an NFS server you will have other
data directories to back up, and these directories might be large.

A [backup process and a link to an example backup script](#backups) is
in the appendix.  We look at backing up both system and data directories.

