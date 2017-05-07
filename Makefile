# Makefile for qmail-xdkim


SRC = clean mkdomainkey qmail-sdkim qmail-vdkim conf

default: $(SRC)
	@echo Done!

clean:
	@echo -n Cleaning up ...
	@rm -f $(SRC)
	@echo " done!"

setup:
	./install

mkdomainkey:
	@echo creating $@
	@cat warn-auto.sh mkdomainkey.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@chmod 755 $@
#        | sed s}UID}"`head -2 conf-users | tail -1`"}g \
#        | sed s}GID}"`head -1 conf-groups`"}g \

qmail-sdkim:
	@echo creating $@
	@cat warn-auto.sh qmail-sdkim.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@chmod 755 $@

qmail-vdkim:
	@echo creating $@
	@cat warn-auto.sh qmail-vdkim.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@chmod 755 $@

conf:
	cat qdkim-conf.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> qdkim.conf
	@chmod 644 qdkim.conf
