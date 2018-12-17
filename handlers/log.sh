#!/bin/sh

while read -r line; do
  echo "$line" | sed -n s/^PING/PONG/p
  >&2 echo "[$(date '+%F %T')] $line"
done
