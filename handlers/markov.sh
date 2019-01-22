#!/bin/sh

mrkdb="./logs.mrkdb.d"

sendmsg() {
  awk -v channel="$channel" \
    '{ print "PRIVMSG",channel,":",$0 }'
}

# slightly modified from https://github.com/Francesco149/markov.sh
# it's biased towards generating longer sentences by ignoring choices that
# would end the sentence unless there's no other choice

mrkwords() {
  file="${1:-~/.mrkdb}"
  n="${2:-1}"
  key="$3"
  [ ! -z "$key" ] && echo "$key"
  [ "$n" -le 0 ] && return
  if [ -z "$key" ]; then
    word=$(shuf -n 1 < "$file" | cut -d' ' -f1)
  else
    word=$(grep -Fw -- "$key" < "$file" |
      awk -v key="$key" '$1 == key && $2 != "" { print $0 }' |
      shuf -n 1 | awk '{ print $2 }') || return
    [ -z "$word" ] && return
  fi
  mrkwords "$file" "$(( n - 1 ))" "$word"
}

getmarkov() {
  if [ -z "$user" ]; then
    if [ ! -z "$pattern" ]; then
      user=$(grep -rFw "$pattern" "$mrkdb" |
        awk -F'[: ]' -v pattern="$pattern" '$3 == pattern { print $0 }' |
        shuf -n 1 | awk -F'[:/]' '{ print $3 }')
    else
      user=$(shuf -n 1 < logs.txt | awk -F ':' '{ print $1 }')
    fi
  fi
  msg=$(
    printf "$user: " &&
    mrkwords "$mrkdb/$user:" 20 "$pattern" | tr '\n' ' '
  ) && echo "$msg"
}

handlemarkov() {
  n=$(echo "$cmd" | sed 's/[^0-9]//g')
  n=$(( n + 0 ))
  [ $n -eq 0 ] && n=$(( n + 1 ))
  if [ $n -gt 3 ]; then
    n=3
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
      =*) pattern="$(echo "$args" | cut -d '=' -f2- | awk '{ print $1 }')" ;;
    esac
    prev_arg="$arg"
  done
  for i in $(seq "$n"); do
    ( getmarkov ) | sed 's/\<LUL\>/LuL/g' | sendmsg
  done
}

feedmarkov() {
  username=$(echo "$line" | awk -F '[:!]' '{ printf "%s", $2 }')
  [ "$user" = "$username" ] && return
  echo "$line" | tr -d '\r' | awk '{
    sub(/^:/, "", $4)
    for (i = 4; i < NF; i++) {
      print $i,$(i+1)
    }
    print $i
  }' >> "$mrkdb/$username:"
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
      :!markov*) handlemarkov ;;
      :!*) ;;
      *) feedmarkov ;;
    esac
    ;;
  esac
done
