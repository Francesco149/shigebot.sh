#!/bin/sh

while read -r line; do
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/PING/PONG/ ;;
  PRIVMSG)
    channel="$(echo "$line" | awk '{ print $3 }')"
    message="$(echo "$line" | awk '{ print $4 }' | tr -d '\r' |
      tr '[:upper:]' '[:lower:]')"
    echo "$message" | grep -sqwi terry && \
      printf "PRIVMSG $channel :" && shuf -n 1 quotes.txt
    ;;
  esac
done
