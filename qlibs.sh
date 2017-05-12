#!/bin/sh
#********************************************************************************
#

LIBDIR=./../../qlibs
LIBS="pathexec.o buffer.a env.a errmsg.a fd.a qstring.a sig.a stralloc.a time.a"

error() { echo "Couldn't find qlibs. Aborting!"; exit; }

build() {
  make clean
  make check
  make libs
}

[ -d "$LIBDIR" ] || error

cd $LIBDIR
for L in $LIBS ; do [ -f "$L" ] || build ; done
cd $OLDPWD

cp $LIBDIR/pathexec.o pathexec.o
cp $LIBDIR/buffer.a   buffer.a
cp $LIBDIR/env.a      env.a
cp $LIBDIR/errmsg.a   errmsg.a
cp $LIBDIR/fd.a       fd.a
cp $LIBDIR/qstring.a  qstring.a
cp $LIBDIR/sig.a      sig.a
cp $LIBDIR/stralloc.a stralloc.a
cp $LIBDIR/time.a     time.a
