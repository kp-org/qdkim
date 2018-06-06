#********************************************************************************
# Create/Handle domainkeys for openqmail/eQmail/(net)qmail and derivatives      #
#                                                                               #
#  Author: Kai Peter (parts taken from Joerg Backschues), ©2014                 #
# Version: 0.32                                                                 #
# Licence: This program is  Copyright(C) ©2015 Kai Peter.  It can be copied and #
#          modified according to the GNU GENERAL PUBLIC LICENSE (GPL) Version 2 #
#          or a later version. This software comes without any warranty.        #
#                                                                               #
# Description: Creation of domain keys and DNS TXT records for bind             #
#********************************************************************************
DKDIR="QMAILHOME/etc/dkimkeys"

OPENSSL=$(which openssl 2>/dev/null)
if [ $? -ne 0 ] ; then
   echo "Couldn't find openssl! Aborting!" ; exit 0 ; fi

showHelp() {
  echo "Usage:  $(basename $0) [-h] [-p] [-s] domain"
  echo
  echo -e "\t-h\tshow this help and exit"
  echo -e "\t-p\tprint TXT record"
  echo -e "\t-s\tset the selector"
  echo
  exit 1 ; }

while getopts "hps:" O "${@}"; do
  case "${O}" in
    p) PRINT=1;;
    s) SELECTOR=${OPTARG};;
    h) showHelp;;
    *) showHelp;;
  esac
done
shift $((OPTIND-1))

# Validate the input a bit ...
DOMAIN=$1 ; if [ ! $DOMAIN ] ; then showHelp ; fi
# Only one argument is allowed ($1) and have to follow any other options
if [ $2 ] ; then echo $'\e[1m'"Syntax ERROR!"$'\e[0m\n' ; showHelp ; fi
#
if [ ! $SELECTOR ] || [ $SELECTOR = "" ] ; then SELECTOR=default ; fi

showTXT() {
  # backslashes MUST NOT be used in TXT records to quote semicolons !
  echo -e "\e[33m\nTXT record for BIND:\e[37m\n"

  echo -n "$SELECTOR._domainkey.$DOMAIN. IN TXT "
  echo "\"v=DKIM1; k=rsa; t=y; p=`grep -v -e "^-" $DKDIR/$DOMAIN/rsa.public_$SELECTOR | tr -d "\n"`\""
  echo ; }

showError() {
  echo -e $'\n\e[1;37m'" Domainkey for domain \e[36m$DOMAIN\e[37m" \
          "with selector \"$SELECTOR\"\e[1;31m $errString\e[1;37m!";
  echo $'\e[0m' ; exit 1 ; }

if [ ! $PRINT ] ; then
  test -f $DKDIR/$DOMAIN/rsa.private_$SELECTOR && \
  errString="already exists" && showError
  # create a new key for selector
  mkdir -p $DKDIR/$DOMAIN
  echo $SELECTOR > $DKDIR/$DOMAIN/selector
  #
  $OPENSSL genrsa -out $DKDIR/$DOMAIN/rsa.private_$SELECTOR 1024
  $OPENSSL rsa -in $DKDIR/$DOMAIN/rsa.private_$SELECTOR \
               -out $DKDIR/$DOMAIN/rsa.public_$SELECTOR -pubout -outform PEM

  cd "$DKDIR/$DOMAIN"
  ln -sf rsa.private_$SELECTOR default
  cd "$OLDPWD"
#  ln -sf $DKDIR/$DOMAIN/rsa.private_$SELECTOR $DKDIR/$DOMAIN/default
  # set access rights
  chmod 0711 $DKDIR
  chmod 0700 $DKDIR/$DOMAIN
  chmod 0600 $DKDIR/$DOMAIN/*
#QUEUEDIR=`qmail-print | grep 'default queue location:'`
  USR=`ls -l QMAILHOME/var/queue/lock/tcpto | awk '{ print $3 }'`
  GRP=`ls -l QMAILHOME/var/queue/lock/tcpto | awk '{ print $4 }'`
  chown -R $USR:$GRP $DKDIR
 else
  test -f $DKDIR/$DOMAIN/rsa.public_$SELECTOR || \
  (errString="does not exist" && showError)
fi
[ "$?" = 0 ] && showTXT
exit 0
