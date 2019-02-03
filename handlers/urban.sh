#!/bin/sh

printf_cmd="printf"
for c in /usr/bin/printf /bin/printf; do
  if [ -x "$c" ]; then
    printf_cmd="$c"
    break
  fi
done

json_s() {
  # escaped '"$1":"((\\")?[^"])*"'
  LC_ALL=en_US.UTF-8 \
    $printf_cmd "$(grep -oE "\"$1\":\"((\\\\\")?[^\"])*\"" |
    cut -d':' -f2- |
    sed -r 's/\\([^unr])/\1/g;s/\\[nr]/ /g;s/^"//g;s/"$//g;s/%/%%/g')"
}

get_urban() {
  mkdir urban_cache >/dev/null 2>&1
  q=$(echo "$1" | sed 's:[/.]:_:g;s/^[[:space:]]*//g;s/[[:space:]]*$//g')
  resp="urban_cache/$q.json"
  if [ ! -f "$resp" ] || find "$resp" -empty | grep -q "."; then
    curl --get "http://api.urbandictionary.com/v0/define" \
      --data-urlencode "term=$1" > "$resp"
  fi
  text=$(json_s definition < "$resp" |
    awk 'length>100 { print substr($0,0,401)"..."; exit } 1' |
    sed 1q)
  link=$(json_s permalink < "$resp" | sed 1q)
  echo "$text $link"
}

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
      :!urban)
        get_urban "$(echo "$line" | awk '{ $1=$2=$3=$4="" } 1')" |
        sendmsg
        ;;
    esac
    ;;
  esac
done
