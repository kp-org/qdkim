#********************************************************************************
# config file for qmail-xdkim (for both qmail-sdkim and qmail-vdkim)
#
# The values overwrites equivalent environment variables.

# extend the path as necessary
PATH="QMAILHOME/bin:$PATH"

# set dkim tool which creates the signature (DEFAULT: libdkimtest)
XDKIM=xdkim
LIBDK=libqdkim
#
LOGGER="QMAILHOME/bin/splogger"

#********************************************************************************
# options for qmail-sdkim (signing)                                             *
#
# set DOSIGN to an value other than 1 (one) to disable signing
DOSIGN=1

# if qmail-remote was renamed, set the name of the real qmail-remote binary
QMAILREMOTE="QMAILHOME/bin/qmail-remote.bin"
# 
DKDIR="QMAILHOME/etc/domainkeys/%/default"

#
#SIGNLEVEL=

# set the level
PARENTLEVEL=2
#
#SIGNOPTS=

#********************************************************************************
# options for qmail-vdkim (verify)

# set DOVRFY to an value other than 1 (one) to disable signing
DOVRFY=1
#DKVRFY=

DKQUEUE="QMAILHOME/bin/qmail-queue"
