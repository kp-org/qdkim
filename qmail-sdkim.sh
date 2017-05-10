#********************************************************************************
# DKIM signing for openqmail/eQmail/(net)qmail & derivatives                    #
#                                                                               #
#  Author: Kai Peter, ©2013-©2017 (kp@openqmail.org)                            #
#          (based on work by Joerg Backschues & Kyle Wheeler)                   #
# Version: 0.57                                                                 #
# Licence: See file LICENSE file                                                #
#                                                                               #
# Description: Add DKIM signature to outgoing messages                          #
#********************************************************************************
shopt -q -s extglob
PATH="QMAILHOME/bin:$PATH"
HOST="$1"                     # recipient host (will never used below)
SENDER="$2"                   # HAVE TO be valid!

# check for config file and include it
[ -f "QMAILHOME/etc/qdkim.conf" ] && . "QMAILHOME/etc/qdkim.conf"

# these files HAVE TO exists from *qmail, else - bummer
# (Hint: if 'qmail-remote' was renamed, set it in config file!)
[ -f "$QMAILREMOTE" ] || QMAILREMOTE=`dirname $0`"/qmail-remote"
[ -f "$LOGGER" ] || LOGGER="QMAILHOME/bin/splogger"

[ "$DOSIGN" ] || DOSIGN=0    # have to be initialized

DelTmpFiles() { rm -f "$InMsg" "$OutMsg"; }
DoLog() { echo "$LogMsg" | "$LOGGER" qmail-dkim; }
# Important: After the message was signed, send it immediatily!
DoSend() { exec "$QMAILREMOTE" "$@"; exit 0; }

# just for backwards compatibility, but libqdkim is recommended
[ "$DKLIB" ] || DKLIB="QMAILHOME/bin/libqdkim"
if [ ! -f "$DKLIB" ] && [ "$DOSIGN" = "1" ] ; then
  # print a warning, but send the message w/o signature
  LogMsg="warning: couldn't find $DKLIB - message not signed!"
  DoLog ; DOSIGN=0; fi

# if $DOSIGN is NOT set, then signing is disabled at all
if [ ! "$DOSIGN" = "1" ] ; then DoSend "$@" ; fi

# wildcard path to the DKIM/domain keys
[ "$DKSIGN" ] || DKSIGN="QMAILHOME/etc/dkimkeys/%/default"

GetSender() {
  # get domainpart of sender ("$DEFAULTDOMAIN" have to be set by *qmail)
  [[ -z "$SENDER" && "$DEFAULTDOMAIN" ]] && SENDER="@$DEFAULTDOMAIN"
  [ -z "$SENDER" ] && SENDER=@`hostname -f`
  DOMAIN="${SENDER##*@}"
  # sanity-check of the sender - abort sending on failure (RfC 2049)
  # (seems to be a bit outdated(?) as of internationalization (IDN's))
  if [[ $DOMAIN = !(+([a-zA-Z0-9\!\#$%*/?|^{}\`~&\'+=_.-])) ]] ; then
    LogMsg="alert: Address $SENDER contains illegal characters."
    DoLog ; exit 0 ; fi    # log and don't send
}
SubDomain() {
  if [ "$DOMAIN" ] ; then
    # try parent domains
    while [ ! -r "${DKSIGN//\%/$DOMAIN}" ] ; do
      DOMAIN=${DOMAIN#*.}
      DPARTS=( ${DOMAIN//./ } )
      [ ${#DPARTS[*]} -eq 1 ] && DOMAIN="${SENDER##*@}" && break
    done
  fi
  DKSIGN="${DKSIGN//\%/$DOMAIN}"
}

GetSender
SubDomain

# last try to get the domainkey file (if function SubDomain fails)
if [[ $DKSIGN = *%* ]] ; then DKSIGN="${DKSIGN%%%*}${DOMAIN}${DKSIGN#*%}" ; fi

# the signing process itself ****************************************************
if [ -f "$DKSIGN" ] ; then
   InMsg=`mktemp -p /tmp -t sdkim.XXXXXXXXXXXXXXX`
   OutMsg=`mktemp -p /tmp -t sdkim.XXXXXXXXXXXXXXX`
   # sign the message: add CRLF ("\r\n") to every line of the message before
   cat - | sed 's/$'"/`echo \\\r`/" >"$InMsg"
   # this works (in most cases) fine (even with libdkim-1.0.21):
   $DKLIB -y`cat /etc/domainkeys/$DOMAIN/selector` -d"$DOMAIN" -i"$SENDER" \
          -l -b2 -ct -z2 -s "$InMsg" "$DKSIGN" "$OutMsg" 2>/dev/null
   # remove 'CR' and handover to the real qmail-remote
   (cat "$OutMsg" | tr -d '\015') | DoSend "$@"
   EC=$?
   DelTmpFiles
   # write to system log
   LogMsg="created DKIM signature for $2 ($DOMAIN)" ; DoLog
   exit $EC
 else                  # no domainkey found for (sub)domain
   LogMsg"No DKIM key found for $2" ; DoLog
   DoSend "$@"
fi
