#!/bin/sh

sendmsg() {
  awk -v channel="$channel" \
    '{ print "PRIVMSG",channel,":",$0 }'
}

getlogs() {
  if [ ! -z "$user" ] || [ ! -z "$pattern" ]; then
    grep "^${user:-[^:]*}: $pattern" < logs.txt
  else
    shuf -n 1 < logs.txt
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
    else
      return
    fi
  fi
  i=0
  while [ $i -lt $n ]; do
    i=$(( i + 1 ))
    pattern=""
    user=""
    args=$(echo "$line" | awk '{ $1=$2=$3=$4=""; print $0 }' |
      tr -d '\r')
    prev_arg=""
    for arg in $args; do
      case "$prev_arg" in
        u) user="$arg" ;;
        '=?') pattern=".*$arg" ;;
        =) pattern="$arg" ;;
      esac
      case "$arg" in
        '=?'*) pattern=".*$(echo "$arg" | cut -d'?' -f2-)" ;;
        =*) pattern="$(echo "$arg" | cut -d'=' -f2-)" ;;
      esac
      prev_arg="$arg"
    done
    getlogs | shuf -n 1 | sed 's/\<LUL\>/LuL/g' | sendmsg
  done
}

while read -r line; do
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/PING/PONG/ ;;
  PRIVMSG)
    channel="$(echo "$line" | awk '{ print $3 }')"
    cmd="$(echo "$line" | awk '{ print $4 }' | tr -d '\r')"
    case "$cmd" in
      :!logs*) handlelogs ;;
    esac
    ;;
  esac
done
