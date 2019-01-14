#!/bin/sh

while read -r line; do
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/PING/PONG/ ;;
  PRIVMSG)
    channel="$(echo "$line" | awk '{ print $3 }')"
    message="$(echo "$line" | awk '{ print $4 }' | tr -d '\r')"
    case "$message" in
      :!hi)
        n="0x$(xxd -p -g2 -l2 < /dev/urandom)"
        n=$(( n % 10001 ))
        n="$(printf "%03d" $n | sed 's/..$/.&/')"
        echo "PRIVMSG $channel :hi [$n]"
        ;;
    esac
    ;;
  esac
done
