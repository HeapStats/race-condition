<< LICENSE
Copyright (C) 2018 Nippon Telegraph and Telephone Corporation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
LICENSE

#!/bin/bash

pushd $(dirname $0) >/dev/null

function confirm_result() {
  for TESTDIR in `cat ${1:-$PWD/testlist.txt}`; do
    echo -n "$TESTDIR "
    if [ -e $TESTDIR/test-timeout ]; then
      echo -e "\e[33mtimeout\e[m"
    elif [ -e $TESTDIR/test-failed ]; then
      echo -e "\e[31mfailed\e[m"
    elif [ -e $TESTDIR/test-succeeded ]; then
      echo -e "\e[32msucceeded\e[m"
    else
      echo -e "\e[33munknown\e[m"
    fi
  done
}

function clean() {
  TARGET=""
  if [ $# -ne 1 ]; then
    TARGET="."
  else
    TARGET=`cat $1`
  fi
  for target in $TARGET; do
    find $target \( \
    -name "*.class" -o -name "core*" -o -name "hs_err*log" -o \
    -name "*.gdb" -o -name "*.log" -o -name "*command.gdb" -o \
    -name "heapstats_*" -o -name "test-failed" -o -name "test-succeeded" -o \
    -name "test-timeout" -o -name "tmp*" -o -name "core" -o -name "dumping" \
    \) \
    -exec rm -fR {} \;
  done
  rm -fR __pycache__ common.pyc;
}

if [[ $1 == "--clean" ]]; then
  clean $2
  exit
elif [[ $1 == "--result" ]]; then
  confirm_result ${2:-$PWD/testlist.txt}
  exit
fi

declare -A DEFAULT_ULIMITS

function store_ulimits(){
  for item in `ulimit -a | sed -e 's/^.\+\(-.\))\s\+\(.\+\)$/\1,\2/g'`; do
    key=`echo $item | cut -d',' -f 1`
    value=`echo $item | cut -d',' -f 2`
    DEFAULT_ULIMITS[$key]=$value
  done
}

function restore_ulimits(){
  for key in ${!DEFAULT_ULIMITS[@]}; do
    ulimit -S $key ${DEFAULT_ULIMITS[$key]} > /dev/null 2>&1
  done
}

if [ -z "$JAVA_HOME" ]; then
  echo '$JAVA_HOME is not set.'
  exit 1
fi;

if [ -z "$HEAPSTATS_LIB" ]; then
  echo '$HEAPSTATS_LIB is not set.'
  exit 2
fi;

TESTLIST=${1:-$PWD/testlist.txt}

if [ ! -e $TESTLIST ]; then
  echo "$TESTLIST does not exist."
  exit 3
fi

clean $TESTLIST

ulimit -c unlimited
store_ulimits

for TEST_ENTRY in `cat $TESTLIST`; do
  for TESTDIR in `ls -d $TEST_ENTRY`; do
    echo "Run $TESTDIR"

    export TEST_TARGET=$PWD/$TESTDIR
    source $TEST_TARGET/buildenv.sh

    AGENTPATH="-agentpath:$HEAPSTATS_LIB"

    if [ -n "$HEAPSTATS_CONF" ]; then
      AGENTPATH="$AGENTPATH=$HEAPSTATS_CONF"
    fi

    pushd $TEST_TARGET

    TESTNAME=`echo $TESTDIR | sed -e "s/\//-/"`
    cat <<EOF > $TEST_TARGET/${TESTNAME}-command.gdb
set logging file result.log
set logging on
run $AGENTPATH $JAVA_OPTS $MAINCLASS >> result.log 2>&1
EOF

    # Set timeout to kill deadlocked process
    #(sleep 125s && touch test-timeout && pkill -9 gdb) &
    (sleep 300s && if [ ! -e dumping ]; then 
      touch test-timeout;
      kill -9 `ps a | grep $TESTNAME | grep -v grep | cut -d" " -f1` >/dev/null 2>&1;
      if [ $? -ne 0 ]; then
        pkill -9 gdb >/dev/null 2>&1
      fi
    fi) &
    TIMEOUT_PID=$!

    # If select specified gdb, load files and symbols to exec
    if [ -n "$GDB_PATH" ] ; then
      cat <<EOF > $TEST_TARGET/loadfiles.gdb
set sysroot /
set debug-file-directory /usr/lib/debug
set directories /usr/src/debug
set use-deprecated-index-sections on
EOF
      JAVA_LIB=$(find ${JAVA_HOME%/}/ -name "java" -type f | grep -v jre)
      echo "file ${JAVA_LIB}" >> ${TEST_TARGET}/loadfiles.gdb
      JAVA_LIB=${JAVA_LIB%/bin/java}
      echo "set solib-search-path /lib64/:${JAVA_LIB}:${JAVA_LIB}*/jre/lib/amd64/:${JAVA_LIB}*/jre/lib/amd64/*/:${HEAPSTATS_LIB%/*}" >> ${TEST_TARGET}/loadfiles.gdb

      ${GDB_PATH}/bin/gdb -q -x loadfiles.gdb -x test.py -x ${TESTNAME}-command.gdb
    else
      gdb -q -x test.py -x ${TESTNAME}-command.gdb $JAVA_HOME/bin/java
    fi

    if [ $? -ne 0 ]; then
      if [ ! -e test-timeout ]; then
        echo -e "$TESTDIR \e[31mfailed\e[m"
        touch test-failed
      fi
    fi

    if [ $(ps -p $TIMEOUT_PID --no-headers|wc -l) == 1 ]; then 
      kill -9 $TIMEOUT_PID
    fi

    if [ -e test-timeout ]; then
      echo -e "$TESTDIR \e[33mtimeout\e[m"
    else
      ls hs_err*.log > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo -e "$TESTDIR \e[31mfailed\e[m"
        touch test-failed
      else
        ls core* > /dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo -e "$TESTDIR \e[31mfailed\e[m"
          touch test-failed
        else
          echo -e "$TESTDIR \e[32msucceeded\e[m"
          touch test-succeeded
        fi
      fi
    fi

    restore_ulimits
    popd >/dev/null
  done
done

echo
echo "Test summary:"

confirm_result $TESTLIST

popd >/dev/null
