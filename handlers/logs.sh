#!/bin/sh

sendmsg() {
  awk -v channel="$channel" \
    '{ print "PRIVMSG",channel,":",$0 }'
}

getlogs() {
  if [ ! -z "$user" ] || [ ! -z "$pattern" ]; then
    grep "^${user:-[^:]*}: $pattern" < logs.txt
  else
    cat logs.txt
  fi
}

handlelogs() {
  n=$(echo "$cmd" | sed 's/^:!logs//g')
  n=$(( n + 0 ))
  [ $n -eq 0 ] && n=$(( n + 1 ))
  if [ $n -gt 3 ]; then
    if [ $n -eq 99 ]; then
      activity=$(stat -c %Y "logs99.time")
      now="$(date +%s)"
      since=$(( now - activity ))
      if [ $since -lt 86400 ]; then
        return
      fi
      touch "logs99.time"
    else
      return
    fi
  fi
  pattern=""
  user=""
  args=$(echo "$line" | awk '{ $1=$2=$3=$4=""; print $0 }' |
    tr -d '\r')
  prev_arg=""
  for arg in $args; do
    case "$prev_arg" in
      u) user="$arg" ;;
    esac
    case "$arg" in
      me) user=$(echo "$line" | awk -F '[:!]' '{ printf $2 }') ;;
      =*|?=*)
        pattern="$(echo "$args" | cut -d '=' -f2- |
          sed 's/?[[:space:]]*/.*/g')"
      ;;
    esac
    prev_arg="$arg"
  done
  getlogs | shuf -n $n | sed 's/\<LUL\>/LuL/g' | sendmsg
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
      :!logs*) handlelogs ;;
    esac
    ;;
  esac
done
