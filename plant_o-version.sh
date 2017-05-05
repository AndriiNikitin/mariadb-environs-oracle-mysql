#!/bin/bash
set -e

. common.sh

# extract worker prefix, e.g. m12
wwid=${1%%-*}
# extract number, e.g. 12
wid=${wwid:1:100}

port=$((3606+$wid))

workdir=$(find . -maxdepth 1 -type d -name "$wwid*" | head -1)

# if folder exists - it must be empty or have only two empry directories (they may be mapped by parent farm for docker image)
if [[ -d $workdir ]]; then
  ( [[ -d $workdir/dt && "$(ls -A $workdir/dt)" ]] \
  || [[ -d $workdir/bkup && "$(ls -A $workdir/bkup)" ]] \
  || [[ "$(ls -A $workdir | grep -E -v '(^dt$|^bkup$)')" ]] \
  ) &&  { (>&2 echo "Non-empty $workdir aready exists, expected unassigned worker id") ; exit 1; }

  [[ $workdir =~ ($wwid-)([1-9][0-9]?)(\.)([0-9])(\.)([1-9][0-9]?) ]] || ((>&2 echo "Couldn't parse format of $workdir, expected $wwid-version") ; exit 1)
  version=${BASH_REMATCH[2]}.${BASH_REMATCH[4]}.${BASH_REMATCH[6]}
fi

tar=${2-$version}


# we got unzipped tar already - try to retrieve its version
if [[ -d $tar ]]; then
  actual_version=$($tar/bin/mysqld --version)
  [[ $actual_version =~ (.*)(:space:)([1-9][0-9]?)(\.)([0-9])(\.)([1-9][0-9]?)(.*) ]] || { (>&2 echo "Couldn't detect version of mysql") ; exit 1; }
  actual_version = ${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}

  [[ -z $version ]] || [[ $version == $actual_version ]] || { (>&2 echo "Actual version doesn't match requested folder") ; exit 1; }
  version=$actual_version
else 
  [[ $tar =~ ([1-9][0-9]?)(\.)([0-9])(\.)([1-9][0-9]?) ]] || { (>&2 echo "Invalid second parameter ($tar), expected version, e.g. 10.1.20 ") ; exit 1; }

  [[ -z $version ]] || [[ $version == $tar ]] || { (>&2 echo "Scond parameter must match version in pre-created folder") ; exit 1; }
  version=$tar
fi  


workdir=$(pwd)/$wwid-$version
[[ -d $workdir ]] || mkdir $workdir
[[ -d $workdir/dt ]] || mkdir $workdir/dt
[[ -d $workdir/bkup ]] || mkdir $workdir/bkup

# detect windows like this for now
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
  dll=dll
  bldtype=Debug
else
  dll=so
fi

# we copy all files for mariadb environs

for filename in _template/m-{version,all}/* ; do
  m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename \
  | sed s/m-tar/o-tar/g \
  > $workdir/$(basename $filename)
done

for filename in _template/m-{version,all}/*.sh ; do
  chmod +x $workdir/$(basename $filename)
done


# do the same for enabled plugins
for plugin in $ERN_PLUGINS ; do
  [ -d ./_plugin/$plugin/m-version/ ] && for filename in ./_plugin/$plugin/m-version/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename \
    | sed s/m-tar/o-tar/g \
    > $workdir/$(basename $filename)

    chmod +x $workdir/$(basename $filename)
  done

  [ -d ./_plugin/$plugin/m-all/ ] && for filename in ./_plugin/$plugin/m-all/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename \
    > $workdir/$(basename $filename)
    chmod +x $workdir/$(basename $filename)
  done

done

# now we add the same for oracle-mysql specific


for plugin in $ERN_PLUGINS ; do
  [ -d ./_plugin/$plugin/o-version/ ] && for filename in ./_plugin/$plugin/o-version/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename > $workdir/$(basename $filename)
    chmod +x $workdir/$(basename $filename)
  done

  [ -d ./_plugin/$plugin/o-all/ ] && for filename in ./_plugin/$plugin/o-all/* ; do
    MSYS2_ARG_CONV_EXCL="*" m4 -D__wid=$wid -D__workdir=$workdir -D__srcdir=$src -D__blddir=$bld -D__port=$port -D__bldtype=$bldtype -D__dll=$dll -D__version=$version -D__wwid=$wwid -D__datadir=$workdir/dt $filename > $workdir/$(basename $filename)
    chmod +x $workdir/$(basename $filename)
  done

done

:
