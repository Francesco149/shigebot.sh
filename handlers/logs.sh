#!/bin/sh

sendmsg() {
  awk -v channel="$channel" \
    '{ print "PRIVMSG",channel,":",$0 }'
}

getlogs() {
  if [ ! -z "$user" ] || [ ! -z "$pattern" ]; then
    grep -i "^${user:-[^:]*}: $pattern" < logs.txt
  else
    cat logs.txt
  fi
}

handlelogs() {
  n=$(echo "$cmd" | sed 's/[^0-9]//g')
  n=$(( n + 0 ))
  [ $n -eq 0 ] && n=$(( n + 1 ))
  if [ $n -gt 3 ]; then
    n=3
    if [ $n -eq 99 ]; then
      activity=$(stat -c %Y "logs99.time")
      now="$(date +%s)"
      since=$(( now - activity ))
      if [ $since -ge 86400 ]; then
        touch "logs99.time"
        n=99
      fi
    fi
  fi
  pattern=""
  user=""
  args=$(echo "$line" | awk '{ $1=$2=$3=$4=""; print $0 }' |
    tr -d '\r')
  first_arg=$(echo "$args" | awk '{ print $1 }')
  second_arg=$(echo "$args" | awk '{ print $2 }')
  case "$first_arg" in
    u) [ ! -z "$second_arg" ] && user="$second_arg" ;;
    me) user=$(echo "$line" | awk -F '[:!]' '{ printf $2 }') ;;
  esac
  for arg in $args; do
    case "$arg" in
    =*|?=*)
      pattern="$(echo "$args" | cut -d '=' -f2- |
        sed 's/?[[:space:]]*/.*/g;s/^[[:space:]]*//g')"
      break
    ;;
    esac
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
