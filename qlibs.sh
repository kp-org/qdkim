#!/bin/sh
#********************************************************************************
# use qlibs with qdkim

[ -f conf-qlibs ] && QLIBDIR=`head -1 conf-qlibs`
[ "$QLIBDIR" ] || QLIBDIR="../qlibs"    # 

# define which libs are required
QLIBS="pathexec.o buffer.a env.a errmsg.a fd.a qstring.a sig.a stralloc.a time.a"

error() { echo "Couldn't find qlibs. Aborting!"; exit; }

build() {
  cd $QLIBDIR
  make clean
  make check
  make libs
  cd $OLDPWD
}

[ -d "$QLIBDIR" ] || error

# check for pre-compiled libs and if one fails, rebuild all
for L in $QLIBS ; do [ -f "$QLIBDIR/$L" ] || build ; done

cp $QLIBDIR/pathexec.o pathexec.o
cp $QLIBDIR/buffer.a   buffer.a
cp $QLIBDIR/env.a      env.a
cp $QLIBDIR/errmsg.a   errmsg.a
cp $QLIBDIR/fd.a       fd.a
cp $QLIBDIR/qstring.a  qstring.a
cp $QLIBDIR/sig.a      sig.a
cp $QLIBDIR/stralloc.a stralloc.a
cp $QLIBDIR/time.a     time.a
