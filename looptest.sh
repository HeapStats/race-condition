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

if [ -z "$JAVA_HOME" ]; then
  echo '$JAVA_HOME is not set.'
  exit 1
fi;

if [ -z "$HEAPSTATS_LIB" ]; then
  echo '$HEAPSTATS_LIB is not set.'
  exit 2
fi;

mkdir result
now=`date +%Y-%m-%d_%H-%M-%S`
echo $now >> result/result.log

if [ -e list ]; then
  cat list | wc -l >> result/result.log
  bash testcase.sh --result list | grep -E "timeout|fail|unknown" > result/list_$now
else
  cp testlist.txt list
  echo "all testcases" >> result/result.log
fi

while :
do
  if [ `cat list | wc -l` == 0 ]; then
    break
  fi
  bash testcase.sh list
  now=`date +%Y-%m-%d_%H-%M-%S`
  bash testcase.sh --result list | grep -E "timeout|fail|unknown" > result/list_$now
  cat result/list_$now | awk -F" " '{print $1}' > list
  echo $now >> result/result.log
  cat list | wc -l >> result/result.log
done
rm -rf list
