# Makefile for qdkim
#
VERSION=libqdkim-1.0.22
CFLAGS =-c -DVERSION=\"${VERSION}\"
LFLAGS =-lresolv
LIBS   =-lcrypto
#INCL	=  -I /usr/include/openssl/

SRCS = dkim.cpp dns.cpp dkimbase.cpp dkimsign.cpp dkimverify.cpp
OBJS = $(SRCS:.cpp=.o)

default: all conf man
	@echo Done!

all: libqdkim mkdkimkey qmail-sdkim qmail-vdkim

libqdkim.a: $(OBJS)
	rm -f libqdkim.a
	ar cr libqdkim.a $(OBJS)
	ranlib libqdkim.a

libqdkim: libqdkim.a libqdkim.o
	g++ -o libqdkim $(LFLAGS) -L . libqdkim.o $(LIBS) libqdkim.a

libqdkim.o: libqdkim.cpp

.cpp.o:
	g++ $(CFLAGS) $<

clean:
	@echo -n Cleaning up ...
	@rm -f *.o *.tmp libqdkim libqdkim.a Makefile qdkim.conf
	@rm -f mkdkimkey qmail-sdkim qmail-vdkim *.8 qdkim.conf.5
	@echo " done!"

install: setup

setup:
	echo Installing files
	./install

mkdkimkey:
	@echo creating $@
	@cat warn-auto.sh $@.sh | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@
	@chmod 755 $@

qmail-sdkim:
	@echo creating $@
	@cat warn-auto.sh qmail-sdkim.sh | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@
	@chmod 755 $@

qmail-vdkim:
	@echo creating $@
	@cat warn-auto.sh qmail-vdkim.sh | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@
	@chmod 755 $@

conf:
	@cat qdkim-conf.sh | sed s}QMAILHOME}"`head -1 conf-home`"}g > qdkim.conf
	@chmod 644 qdkim.conf

man: mkdkimkey.8 qmail-sdkim.8 qmail-vdkim.8 qdkim.conf.5
	@echo Creating man pages
	@chmod 644 *.8 *.5

libqdkim.8:
	@cat libqdkim.man | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@

mkdkimkey.8:
	@cat mkdkimkey.man | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@

qmail-sdkim.8:
	@cat qmail-sdkim.man | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@

qmail-vdkim.8:
	@cat qmail-vdkim.man | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@

qdkim.conf.5:
	@cat qdkim.conf.man | sed s}QMAILHOME}"`head -1 conf-home`"}g > $@
