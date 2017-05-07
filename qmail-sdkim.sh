#********************************************************************************
# DKIM signing for openqmail/eQmail/(net)qmail & derivatives                    #
#                                                                               #
#  Author: Kai Peter, ©2013 (kp@dyndn.es)                                       #
#          based on work by Joerg Backschues & Kyle Wheeler                     #
# Version: 0.5                                                                  #
# Licence: see file LICENSE                                                     #
#                                                                               #
# Description: wrapper around qmail-remote to add DKIM signature(s)             #
#              (permissions should to be 0755)                                  #
#********************************************************************************
shopt -q -s extglob
HOST="$1"                     # recipient host (will never used below)
SENDER="$2"                   #

# check for config file and include it
[ -f "QMAILHOME/etc/qdkim.conf" ] && . "QMAILHOME/etc/qdkim.conf"

# Critical: this error have to be catched and logged immediatily
[ ! -f "$QMAILREMOTE" ] || QMAILREMOTE=`dirname $0`"/qmail-remote"
if [ ! -f "$QMAILREMOTE" ] ; then
   [ "$QMAILREMOTE" ] || QMAILREMOTE="alternative 'qmail-remote' program"
   echo "alert: Couldn't find $QMAILREMOTE! Aborting!"
   exit 111
fi

# Important: as the message was manipulated (usually),  'qmail-remote' HAVE TO be
# called here! If a message will be manipulated *after* it was signed with a DKIM
# key, every verification at the recipient side will fail!
DoSend() { exec "$QMAILREMOTE" "$@"; exit 0; }

# at least, if 'splogger' is missing - bummer
[ "$LOGGER" ] || LOGGER="QMAILHOME/bin/splogger"
[ "$DKLIB"  ] || DKLIB="QMAILHOME/bin/libqdkim"
if [ ! -f "$DKLIB" ] ; then
  # print a warning, but send the message w/o signature
  echo "warning: couldn't find $DKLIB - message not signed!" | $LOGGER $0
  DOSIGN=0
fi

# if $NOSIGN is set then signing is disabled at all
#DOSIGN=1  # @debug
if [ ! "$DOSIGN" = "1" ] ; then DoSend "$@" ; fi

# wildcard path to the domain keys
[ "$DKSIGN" ]  || $DKSIGN="QMAILHOME/etc/dkimkeys/%/default"

GetSender() {
  # Usually the sender comes from qmail-rspawn, otherwise try this...
  [[ -z "$SENDER" && "$DEFAULTDOMAIN" ]] && SENDER="@$DEFAULTDOMAIN"
  [ -z "$SENDER" ] && SENDER=@`hostname -f`
  DOMAIN="${SENDER##*@}"
  # do a sanity-check of the sender,
  # what seems to be a bit outdated(?) as of internationalization (IDN's)
  if [[ $DOMAIN = !(+([a-zA-Z0-9\!\#$%*/?|^{}\`~&\'+=_.-])) ]] ; then
    echo "qmail-remote: Address $SENDER contains illegal characters." | \
    $LOGGER qmail-dkim ; exit 0 ; fi
}
SubDomain() {
  if [ "$DOMAIN" ] ; then
    # try parent domains, per RFC 4871, section 3.8
    while [ ! -r "${DKSIGN//\%/$DOMAIN}" ] ; do
      DOMAIN=${DOMAIN#*.}
      DPARTS=( ${DOMAIN//./ } )
      [ ${#DPARTS[*]} -eq 1 ] && DOMAIN="${SENDER##*@}" && break
    done
  fi
  DKSIGN="${DKSIGN//\%/$DOMAIN}"
}
ParentDomain() {
  [ $PARENTLEVEL ] || PARENTLEVEL="2"
  # Use the parent (second level) domain always (static, never use/try subdomain)
  TLD=`echo $FQDN | awk 'BEGIN {FS = "."} {print $NF}'`
  DOM=`echo $FQDN | awk 'BEGIN {FS = "."} {print $(NF-1)}'`
  DOMAIN=$DOM.$TLD
  # third level parent domain
  if [ PARENTLEVEL -gt 2 ] ; then
     DOM=`echo $FQDN | awk 'BEGIN {FS = "."} {print $(NF-2)}'`
     DOMAIN=$DOM.$DOMAIN
  fi
  # forth level parent domain
  if [ PARENTLEVEL -gt 3 ] ; then
     DOM=`echo $FQDN | awk 'BEGIN {FS = "."} {print $(NF-3)}'`
     DOMAIN=$DOM.$DOMAIN
  fi
  # fifth level parent domain
  if [ PARENTLEVEL -gt 4 ] ; then
     DOM=`echo $FQDN | awk 'BEGIN {FS = "."} {print $(NF-4)}'`
     DOMAIN=$DOM.$DOMAIN
  fi
}

# There are 3+ scenarios to sign (SL - sign level):
# 1) try to sign the correct subdomain, otherwise sign with parent domain
# 2) try to sign the correct subdomain and don't sign on failure
# 3) sign any mail with the parent 'second/third/forth' level domain
# *) don't sign
SL=$SIGNLEVEL ; if [ ! $SL ] then SL=1 ; fi
case $SL in
  1) GetSender ; SubDomain        ;;
  2) GetSender                    ;;
  3) FQDN=${2##*@} ; ParentDomain ;;
  *) DoSend "$@"                  ;;
esac

# last try to get the domainkey file (if function SubDomain fails)
if [[ $DKSIGN = *%* ]] ; then DKSIGN="${DKSIGN%%%*}${DOMAIN}${DKSIGN#*%}" ; fi

# the signing process itself ****************************************************
if [ -f "$DKSIGN" ] ; then
   # domain with domainkey
   InMsg=`mktemp -p /tmp -t sdkim.XXXXXXXXXXXXXXX`
   OutMsg=`mktemp -p /tmp -t sdkim.XXXXXXXXXXXXXXX`
   # sign the message: add CRLF ("\r\n") to every line of the message before
   cat - | sed 's/$'"/`echo \\\r`/" >"$InMsg"
   # this works (in most cases) fine with libdkim-1.0.21:
   $DKLIB -y`cat /etc/domainkeys/$DOMAIN/selector` -d"$DOMAIN" -i"$SENDER" \
          -l -b2 -cr -z2 -s "$InMsg" "$DKSIGN" "$OutMsg" 2>/dev/null
   # remove 'shift in' and handover to the real qmail-remote
   (cat "$OutMsg" | tr -d '\015') | DoSend "$@"
   EC=$?
   rm -f "$InMsg" "$OutMsg"
   # write to system log
   echo "qmail-remote: created DKIM signature for $2 ($DOMAIN)" | $LOGGER qmail-dkim;
   exit $EC
 else                  # no domainkey found for (sub)domain
   echo "qmail-remote: No DKIM key found for $2" | $LOGGER qmail-dkim;
   DoSend "$@"
fi
