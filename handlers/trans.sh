#!/bin/sh

sendmsg() {
  awk -v channel="$channel" \
    '{ print "PRIVMSG",channel,":",$0 }'
}

while read -r line; do
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/PING/PONG/ ;;
  PRIVMSG)
    channel="$(echo "$line" | awk '{ print $3 }')"
    cmd="$(echo "$line" | awk '{ print $4 }' | tr -d '\r' |
      tr '[:upper:]' '[:lower:]')"
    case "$cmd" in
      :!translate)
        trans -b "$(echo "$line" | awk '{ $1=$2=$3=$4="" } 1')" |
        sendmsg
        ;;
    esac
    ;;
  esac
done
