# qdkim

Handle DKIM with eQmail or derivatives and alternatives.

Name conventions:
  - *qmail is a synonym for qmail, netqmai, eQmail, s/qmail and similar forks
  - OMAILHOME is the home directory, in qmail-1.03 '/var/qmail', include the sub-
    folders hierarchy.

qdkim is a plugin for *qmail  like mail servers.  It consits of libqdkim and some
wrappers around it. qdkim consolidates the formerly published packages  xdkim and
qmail-xdkim. Thus, the consolidated packages became obsolete. The change log from
the old ones are appended to the package change log.

libqdkim (xdkim) was forked from libdkim. In 2016 the libdkim project  was marked
in-active on sourceforge. The last version available was libdkim-1.0.21. The code
was stripped down,  all WIN32 stuff  was (hopefully) removed.  The shared library
functionality is gone. The 'library'  is linked statically against  libqdkim now,
an executable like the former libdkimtest.

qdkim is available as part of openqmail.

Requirements

libqdim needs openssl >0.9.8, recommended is >1.0.1r. It is recommended
to use GNU gcc (g++) 4.8 or newer to compile the source.

  - an existing *qmail installation (e.g. in /var/qmail)
  - bourne shell (/bin/sh) or a full compatible shell
  - g++ (gcc)

Installation

To install qdkim run:
  $ ./configure
  $ make
  $ make install

Everything will be installed inside the existing QMAILHOME.

Configuration

0. stop *qmail
1. Verification with qmail-vdkim
   - set QMAILQUEUE=QMAILHOME/bin/qmail-vdkim
2. Signing with qmail-sdkim
   a) mv qmail-remote qmail-remote.bin
   b) ln -s qmail-sdkim qmail-remote
     --> this is the 'classic' way (better: use qmail-bfrmt)
   c) run mkdkimkeys to create a domainkey and publish it in DNS
3. in 'QMAILHOME/{etc/control}/qdkim.conf set:
   DOVRFY=1
   DOSIGN=1
   QMAILREMOTE=QMAILHOME/bin/qmail-remote.bin
4. start *qmail


* libqdkim was tested to run on Linux-like systems only.
  - Gentoo linux
  - Debian 7 "Wheezy"
  - openSuSE 13.2
 (- FreeBSD 10.2   --> really? couldn't remember)
