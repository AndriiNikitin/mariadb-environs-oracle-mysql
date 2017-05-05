#!/bin/bash

# example url  https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.18-linux-glibc2.5-x86_64.tar.gz 

ver=__version
major=${ver%\.*}

FILE=https://dev.mysql.com/get/Downloads/MySQL-${major}/mysql-${ver}-linux-glibc2.5-x86_64.tar.gz

mkdir -p __workdir/../_depot/o-tar/__version

( cd __workdir/../_depot/o-tar/__version && \
[[ -f $(basename $FILE) ]] || wget -nc $FILE && tar -zxf $(basename $FILE) --strip 1 )
