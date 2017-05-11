# qdkim

Handle DKIM with eQmail or derivatives and alternatives.

Name conventions:
  - *qmail is a synonym for qmail, netqmail, eQmail, s/qmail and similar packages
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
