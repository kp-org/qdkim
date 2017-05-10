# Makefile for qmail-dkim

SRC = clean mkdkimkey qmail-sdkim qmail-vdkim conf

default: $(SRC)
	@echo Done!

clean:
	@echo -n Cleaning up ...
	@rm -f $(SRC) *.8
	@echo " done!"

setup:
	./install

mkdkimkey:
	@echo creating $@
	@cat warn-auto.sh $@.sh \
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

man: mkdkimkey.8
#	@chmod 644 *.8

mkdkimkey.8:
	cat mkdkimkey.man \
	| sed s}QMAILHOME}"`head -1 conf-home`"}g \
	> mkdkimkey.8
