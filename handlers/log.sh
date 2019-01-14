#!/bin/sh

while read -r line; do
  >&2 echo "$line"
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/PING/PONG/ ;;
  PRIVMSG) #:user!user@user.tmi.twitch.tv PRIVMSG #channel :text\r\n
    username=$(echo "$line" | awk -F '[:!]' '{ printf "%s: ", $2 }')
    [ "$user: " = "$username" ] && continue
    msg=$(echo "$line" | cut -d ':' -f3-)
    case "$msg" in
      !*) continue ;;
      *) ( printf "%s" "$username" && echo "$msg" ) |
        tr -d '\r' >>logs.txt ;;
    esac
    ;;
  esac
done
