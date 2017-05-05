# Makefile for qmail-xdkim


SRC = mkdomainkey qmail-sdkim qmail-vdkim

default: $(SRC)

clean:
	rm $(SRC)

setup:
	./install

mkdomainkey:
	cat warn-auto.sh mkdomainkey.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@echo creating $@
	@chmod 755 $@
#        | sed s}UID}"`head -2 conf-users | tail -1`"}g \
#        | sed s}GID}"`head -1 conf-groups`"}g \

qmail-sdkim:
	cat qmail-sdkim.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@echo creating $@
	@chmod 755 $@

qmail-vdkim:
	cat qmail-vdkim.sh \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> $@
	@echo creating $@
	@chmod 755 $@
