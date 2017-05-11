#********************************************************************************
# config file for qmail-sdkim and qmail-vdkim                                   *
#                                                                               *
# IMPORTANT: use the absolute path for files always!                            *
#********************************************************************************
# Section 1: 
# set dkim tool which creates the signature (DEFAULT: libqdkim)
DKLIB="QMAILHOME/bin/libqdkim"
# 
LOGGER="QMAILHOME/bin/splogger"

#********************************************************************************
# Section 2: options for qmail-sdkim (signing)                                  *
#
# set DOSIGN=1 to enable signing
DOSIGN=1
# if qmail-remote was renamed, set the name of the real qmail-remote binary
# 
#QMAILREMOTE="QMAILHOME/bin/qmail-remote"
# 
#DKSIGN="QMAILHOME/etc/dkimkeys/%/default"

#********************************************************************************
# Section 3: options for qmail-vdkim (verify)                                   *
# set DOVRFY=1 to enable verification
DOVRFY=1
#
#DKQUEUE="QMAILHOME/bin/qmail-queue"
