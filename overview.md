<!-- -->
# Overview {#chapter-01}

Single-board computers (SBC) are both inexpensive and reliable; they
are also very small.  As such they make excellent 24x7 home servers.
This guide steps you through the process of creating such a server.

This guide has been tested on a Raspberry Pi 400, which is very similar
to a Raspberry Pi 4b.  The main difference it that the RP 400 board
is embedded in a small keyboard.

I also have another SBC, an [ODROID][odroid] still running Ubuntu LTS 16.04,
and I will document it as well as I update it.  I am not sure yet whether
I will document it here, or as another mini-document.  For now I am
focusing on the Raspberry Pi.

One of my goals is to promote using the command-line to do most of the work.
If you are interested in expanding your horizons and understanding
more about the command-line, then this guide is for you.  There is also a lot
of detail in this guide; this is my personal preference.  I grow tired
of the current trend to provide internet-searched answers in a few phrases
to fit on the screen of a mobile phone.

Take a look at the table of contents at the top of the document.  Some users
will only be interested in creating a 24x7 local file-sharing (Samba) service
at home -- in that case you do not need to read beyond the section on 'Backups'.
Of course, people familiar with Linux and the command-line will skip some
sections of this guide.

[odroid]: https://www.hardkernel.com/

## A few issues before you begin {#reserved-address}

You should look into assigning a permanent network IP address for your server
in your home network so that you can easily connect to it from any of your
devices.  Your home network router/WiFi modem should have the
option to enable you to reserve an IP address for any device.  You only need
to know the hardware MAC address of your future server.  There will be 2
MAC addresses - one for hardwired ethernet and one for wireless.
You can reserve both interfaces until you decide which way you will connect
your server to your router.

<!-- mention in document somewhere about getting MAC addrs early -->

## About this document {#doc}

This guide was created in the [*Markdown*][md] markup language (the
Pandoc flavour of Markdown).  Markdown is wonderfully simple.  Then,
using the versatile [Pandoc][pandoc] command set, both HTML and PDF formats of
the document were generated.  In fact this document was created using the home
server as a remote desktop.  The server served as a git, web and NFS server;
as well it served as a remote desktop for contemporary documentation creation.

The appendix of this document is rather large.  The idea is to push some
of the command-line and technical detail into the appendix.  Thus the flow of
the document covers the basics, encouraging the reader to see the bigger 
picture and to avoid being smothered in the detail.

In this guide command-line sessions appear in a pale-yellow box, using a 
customized *.console* Markdown syntax highlighting convention which I
created [for command-line input and output][console-project].  Two kinds
of simplified command-line prompts appear.  As well, explanatory comments
starting with two slashes are coloured blue:

```console
// Usually your prompt would be more complex, something like this:
//    myname@ubuntu:~/.vim/syntax$
// or like this:
//    [desktop /tmp]$ 
// But I simplify its appearance when illustrating command-line sessions.
// Normal Users' command-line prompt, coloured 'green':
$ some-command

// The root superuser's prompt, simplifed also, and coloured 'red':
# some-other-command
```

From my experience creating this guide I added another git repository
containing the examples of the Markdown documentation style and support files 
[used in this guide][pandoc-markdown].

Sometimes command output is long and/or uninteresting in the context
of this guide.  I might show such segments with a ellipsis (**...**)

Sometimes a double-exclamation (**!!**) mark may appear somewhere -- this
is only a reminder for myself to fix an issue at that point in the
documentation.  These reminders will eventually disappear.

I tend to use 'ssh' as a verb - it is not really correct to do this, but it
really is a verb in my life.  So I apologize if it annoys you.

If you discover issues with instructions in this document, or have other
comments or suggestions then you can contact me on
[my github project page][mygithub].

[md]: https://www.markdownguide.org/getting-started/
[pandoc]: https://pandoc.org/
[mygithub]: https://github.com/deatrich/
[console-project]: https://github.com/deatrich/console-syntax/
[pandoc-markdown]: https://github.com/deatrich/doc-with-pandoc-markdown/

