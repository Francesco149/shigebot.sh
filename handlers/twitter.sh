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
    sed -r 's/\\([^un])/\1/g;s/\\n/ /g;s/^"//g;s/"$//g;s/%/%%/g')"
}

get_tweet() {
  mkdir tweet_cache >/dev/null 2>&1
  resp="tweet_cache/$1.json"
  if [ ! -f "$resp" ] || find "$resp" -empty | grep -q "."; then
    curl --silent --header "Authorization: Bearer $twitter_bearer"\
      "https://api.twitter.com/1.1/statuses/show/$1.json" > "$resp"
  fi
  text=$(json_s text < "$resp")
  media=$(json_s media_url < "$resp" | sed 1q)
  video=$(json_s url < "$resp" | grep "video\.twimg\.com" |
    sort -nr | sed 1q)
  [ ! -z "$video" ] && media="$video"
  echo "🐦 $text $media 🐦"
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
    surl=$(echo "$line" | grep -o 'https://t.co/[a-zA-Z0-9]*')
    [ ! -z "$surl" ] &&
      url=$(curl -Ls -o /dev/null -w '%{url_effective}' "$surl")
    [ -z "$url" ] && url="$line"
    id=$(echo "$url" |
      grep -o 'twitter.com/[a-zA-Z0-9_]*/status/[0-9]*' |
      cut -d'/' -f4)
    [ ! -z "$id" ] && get_tweet "$id" | sendmsg
    url=""
    ;;
  esac
done
