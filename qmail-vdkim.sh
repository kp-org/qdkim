#********************************************************************************
# DKIM verification for openqmail/eQmail/(net)qmail and derivatives             #
#                                                                               #
#  Author: Kai Peter (kp@openqmail.org), ©2014,©2017                            #
# Version: 0.49                                                                 #
# Licence: see LICENSE file                                                     #
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

DelTmpFiles() { rm -f $HEAD $BODY $tMsg; }
DoLog() { echo "$LogMsg" | $LOGGER qmail-vdkim; }

# just for backwards compatibility (libqdkim is preferred)
[ "$DKLIB"  ] || DKLIB="QMAILHOME/bin/libqdkim"
if [ ! -f "$DKLIB" ] && [ "$DOVRFY" = "1" ] ; then
  LogMsg="warning: couldn't find $DKLIB - unable to verify message"
  DoLog ; DOVRFY=0 ; fi

# check for needed external tools (--> move this to configure?)
for f in unix2dos
do
  which $f 2>/dev/null
  if [ $? -ne 0 ] ; then
     LogMsg="warning: Missing: $f, no verification possible."
     DoLog ; DOVRFY=0 ; fi
done
if [ ! "$DOVRFY" = "1" ] ; then $DKQUEUE "$@"; exit 0 ; fi

#********************************************************************************
# try to verify DKIM signature(s) ***********************************************
# first set some default vars
[ -d "QMAILHOME/tmp" ] && TMPDIR="QMAILHOME/tmp" || TMPDIR="/tmp"
DONEBY=`basename $0`" at "`hostname` # This doesn't confirm exactily with RfC6376
DOMAIN="unknown"   # default assumption
VALID="fail"       # default assumption
tMsg=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
HEAD=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
BODY=`mktemp -p "$TMPDIR" -t vdkim.XXXXXXXXXXXXXXXXXXX`
#cat - >"$tMsg"     # save the message
QMAILHOME/bin/qdkimcrlf cat - >"$tMsg"

# check for header 'DKIM-Signature'
cat $tMsg | grep "^DKIM-Signature" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
  LogMsg="qmail-vdkim: no DKIM signatures found." ; DoLog
  cat "$tMsg" | $DKQUEUE "$@" ; rm -f "$tMsg" ; exit 0 ; fi

# get from domain from "From:" field
DOMAIN=$(cat $tMsg | grep ^[Ff]rom: | grep '@' | tr -d '\15' | cut -d@ -f2 | cut -d\> -f1)

#unix2dos "$tMsg"     # --> !!!! IMPROVE THIS !!!!!!

# redirection of stderr and pipe to /dev/null is a MUST!
$DKLIB -v $tMsg | grep 'Signature #[0-9]: Success' 2>&1 >/dev/null
if [ $? -eq 0 ] ; then VALID="pass (ok)" ; fi

# get the message body
cat $tMsg | sed 's/\r//' | sed '1,/^$/d' > $BODY
# get the message headers and insert new header field (DKIM-Verify)
cat $tMsg | sed 's/\r//' | sed '/^$/q' | \
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > $HEAD
#printf "X-Authentication-Results: $DOMAIN; dkim=$VALID ($DONEBY)\n\n" | \
printf "X-Authentication-Results: dkim=$VALID ($DONEBY)\n\n" | \
       fmt -w 78 -t >> $HEAD
# concatenate header and body together again
cat "$HEAD" "$BODY" | "$DKQUEUE" "$@"
EC=$?
LogMsg="qmail-vdkim: Verify DKIM for $DOMAIN: $VALID" ; DoLog
#LogMsg="qmail-vdkim: Verify DKIM: $VALID" ; DoLog
DelTmpFiles
exit $EC
