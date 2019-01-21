#!/bin/sh
# this generates one mrkdb file per user and takes logs.txt from shigebot in stdin.
# it prints every 1000th line number to stderr as a means to check progress
#
# usage:
# cd /path/to/shigebot
# ./mrklogs.sh < logs.txt

# sorting lines greatly improves performance because awk probably reuses the
# previous file descriptor.

dbdir="${1:-./logs.mrkdb.d}"
[ -d "$dbdir" ] || mkdir -p "$dbdir" || exit
( cd "$dbdir" || exit
  sort | awk '{
    for (i = 2; i <= NF; i++) {
      print $i,$(i+1) >> $1
    }
    if (NR % 1000 == 0) {
      print NR > "/dev/stderr"
    }
  }' )
