#!/bin/bash
#********************************************************************************
# DKIM verification for openqmail/eQmail/(net)qmail and derivatives             #
#                                                                               #
#  Author: Kai Peter (kp@openqmail.org), ©2014                                  #
# Version: 0.42-beta                                                            #
# Licence: This program is Copyright  ©2015 by Kai Peter.  It can be copied and #
#          modified according to the GNU GENERAL PUBLIC LICENSE (GPL) Version 2 #
#          or a later version. This software comes without any warranty.        #
#                                                                               #
# Description: Verification of DKIM signatures and writing of the header line   #
#              "Authentication-Results:".                                       #
#********************************************************************************
[ "$DKQUEUE" ] || DKQUEUE=/var/qmail/bin/qmail-queue
[ "$DKVRFY" ] || DKVRFY=1

# initialize some vars
[ $LOGGER ] || LOGGER="OMAILHOME/bin/splogger"
LogMsg=""

function DelTmpFiles() { rm -f $HEAD $BODY $tMsg; }
function DoLog() { echo "$LogMsg" | $LOGGER qmail-dkim; }
# queue message w/o verification and exit
function DoQueue {
  cat "$tMsg" | $DKQUEUE "$@"
  DelTmpFiles
  exit 0; }

# check for needed external tools
for f in unix2dos xdkim libdkimtest
do
  which $f 2>/dev/null
  if [ $? -ne 0 ] ; then
     LogMsg="qmail-vdkim: Missing: $f, no verification possible."
     DoLog ; DKVRFY=0 ; fi
done
# first of all save the message
tMsg=`mktemp -p /tmp -t vdkim.XXXXXXXXXXXXXXXXXXX`
cat - >"$tMsg"
# silently give the message to qmail-queue
if [ "$DKVRFY" -eq 0 ] ; then DoQueue ; fi

#********************************************************************************
# try to verify DKIM signature(s) - first set some default vars
DONEBY=`basename $0`" at "`hostname` # This doesn't confirm exactily with RfC6376
DOMAIN="unknown"
XDKIM=xdkim                          # set libdkimtest here if necessary
VALID="fail"
HEAD=`mktemp -p /tmp -t vdkim.XXXXXXXXXXXXXXXXXXX`
BODY=`mktemp -p /tmp -t vdkim.XXXXXXXXXXXXXXXXXXX`
# check for header 'DKIM-Signature'
cat $tMsg | grep "^DKIM-Signature" 2>&1 >/dev/null
if [ $? -ne 0 ] ; then
    LogMsg="qmail-vdkim: no DKIM signatures found."
    DoLog ; DoQueue ; fi

# get from domain from "From:" field
DOMAIN=$(cat $tMsg | grep ^[Ff]rom: | grep '@' | cut -d@ -f2 | cut -d\> -f1)
unix2dos "$tMsg"
# redirection of stderr and pipe to /dev/null is a MUST!
$XDKIM -v $tMsg | grep 'Signature #[0-9]: Success' 2>&1 >/dev/null
if [ $? -eq 0 ] ; then VALID="pass (ok)" ; fi

# get the message body
cat $tMsg | sed 's/\r//' | sed '1,/^$/d' > $BODY
# get the message headers and insert new header field (DKIM-Verify)
cat $tMsg | sed 's/\r//' | sed '/^$/q' | \
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > $HEAD

printf "X-Authentication-Results: $DOMAIN; dkim=$VALID ($DONEBY)\n\n" | \
       fmt -w 78 -t >> $HEAD
# put header and body together again
cat $HEAD $BODY | $DKQUEUE "$@"
EC=$?
LogMsg="qmail-vdkim: Verify DKIM for $DOMAIN: $VALID" ; DoLog
DelTmpFiles
exit $EC
