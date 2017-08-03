#********************************************************************************
# DKIM verification for openqmail/eQmail/(net)qmail and derivatives             #
#                                                                               #
#  Author: Kai Peter (kp@openqmail.org), ©2014,©2017                            #
# Version: 0.55                                                                 #
# Licence: see file LICENSE                                                     #
#                                                                               #
# Description: Verification of DKIM signatures and writing of the header line   #
#              "Authentication-Results:".                                       #
#********************************************************************************
PATH="QMAILHOME/bin:$PATH"
# check for config file and include it
[ -f "QMAILHOME/etc/qdkim.conf" ] && . "QMAILHOME/etc/qdkim.conf"

# these files HAVE TO exists from *qmail, else - bummer
[ -f "$DKQUEUE" ] || DKQUEUE=`dirname $0`"/qmail-queue"
# do not use 'test -f' because $LOGGER could have params
[ "$LOGGER" ] || LOGGER="QMAILHOME/bin/splogger"

[ "$DOVRFY" ] || DOVRFY=0    # make sure it is initialized

DelTmpFiles() { rm -f $HEADER $inMsg $tmpMsg; }
DoLog() { echo "$LogMsg" | $LOGGER qmail-vdkim; }

# just for backwards compatibility (libqdkim is preferred)
[ "$DKLIB"  ] || DKLIB="QMAILHOME/bin/libqdkim"
if [ ! -f "$DKLIB" ] && [ "$DOVRFY" = "1" ] ; then
  LogMsg="warning: couldn't find $DKLIB - unable to verify message"
  DoLog ; DOVRFY=0 ; fi

if [ ! "$DOVRFY" = "1" ] ; then $DKQUEUE "$@"; exit 0 ; fi

#********************************************************************************
# try to verify DKIM signature(s) ***********************************************
# first set some default vars
[ -d "QMAILHOME/tmp" ] && TMPDIR="QMAILHOME/tmp" || TMPDIR="/tmp"
[ `uname -s | tr 'A-Z' 'a-z'` = "linux" ] && O="-f"    # ... and again BSD  >:(
HOSTNAME=`hostname "$O" | tr 'A-Z' 'a-z'`
DONEBY="$HOSTNAME"  # doesn't confirm with RfC6376 exatily
DOMAIN="unknown"    # initialize
VALID="fail"        # default assumption
inMsg=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
if [ ! -f "$inMsg" ] ; then
  LogMsg="Couldn't create temporary file! DKIM verification aborted!"
  DoLog ; $DKQUEUE "$@" ; exit 0
fi
cat - >"$inMsg"     # save the message

# check for header 'DKIM-Signature'
cat "$inMsg" | grep "^DKIM-Signature" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
  LogMsg="No DKIM signatures found." ; DoLog
  cat "$inMsg" | $DKQUEUE "$@" ; rm -f "$inMsg" ; exit 0 ; fi

tmpMsg=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
HEADER=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
# we need CRLF line endings for verification
QMAILHOME/bin/qdkimcrlf cat "$inMsg" >"$tmpMsg"

# redirection of stderr and pipe to /dev/null is a MUST!
$DKLIB -v "$tmpMsg" | grep 'Signature #[0-9]: Success' 2>&1 >/dev/null
if [ $? -eq 0 ] ; then VALID="pass (ok)" ; fi

# get the message body - just a coding reference here :))
#cat $tmpMsg | sed 's/\r//' | sed '1,/^$/d' > $BODY
# get the message headers --> not needed!
#cat "$tmpMsg" | sed 's/\r//' | sed '/^$/q' | \
#    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$HEADER"

# get domain from "From:" header field
DOMAIN=$(cat $inMsg | grep ^[Ff]rom: | tr -d '\15' | cut -d@ -f2 | cut -d\> -f1)
# prepare new header field(s)
printf "X-Authentication-Results: $DOMAIN; dkim=$VALID; $DONEBY\n" | \
       fmt -w 78 -t > "$HEADER"
# concatenate new header field (DKIM-Verify) and message
cat "$HEADER" "$inMsg" | "$DKQUEUE" "$@"
EC=$?
LogMsg="Verify DKIM for $DOMAIN: $VALID" ; DoLog
DelTmpFiles
exit $EC
