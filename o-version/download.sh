#!/bin/bash

# example url  https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.18-linux-glibc2.5-x86_64.tar.gz 

ver=__version
major=${ver%\.*}

file=https://dev.mysql.com/get/Downloads/MySQL-${major}/mysql-${ver}-linux-glibc2.5-x86_64.tar.gz

mkdir -p __workdir/../_depot/o-tar/__version

( 
cd __workdir/../_depot/o-tar/__version

function cleanup {
  [ -z "$wgetpid" ] || kill "$wgetpid" 2>/dev/null
}

trap cleanup INT TERM

if [ ! -f "$(basename $file)"  ] ; then 
  echo downloading "$file"
  wget -q -np -nc $file &
  wgetpid=$!
  while kill -0 $wgetpid 2>/dev/null ; do
    sleep 10
    echo -n .
  done
  wait $wgetpid
  res=$?
  wgetpid=""
  if [ "$res" -ne 0 ] ; then
    >&2 echo "failed to download '$file' ($res)"
    exit $res 
  fi
fi

if [ -f "$(basename $file)" ] ; then 
  if [ ! -x bin/mysqld ] ; then
    tar -zxf "$(basename $file)" ${ERN_M_TAR_EXTRA_FLAGS} --strip 1
  fi
fi
)
:
