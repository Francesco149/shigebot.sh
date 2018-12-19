#!/bin/sh

client_id=zy14okmerr57bokfsd1hsla0snm4ys
irc_server="irc.twitch.tv:6697"

errcho() { (>&2 echo "${@}") }

stfu() {
  "$@" >/dev/null 2>&1
  return $?
}

for p in openssl awk grep mkfifo touch; do
  if ! stfu command -v "$p"; then
    echo "$p was not found, please install it"
    exit 1
  fi
done

urlopen() {
  for b in xdg-open "$BROWSER" qutebrowser firefox chromium-browser \
    google-chrome-stable midori surf qupzilla icecat dillo
  do
    if stfu command -v "$b"; then
      "$b" "$@" || exit
      return
    fi
  done
  echo "no browser found"
  exit 1
}

consume_request() {
  while read -r ln; do
    [ -z "$ln" ] && break
  done
}

consume_request_get_token() {
  read -r req
  consume_request
  state=$(echo "$req" | grep -o 'state=.*' | awk -F '[=&]' '{ print $2 }')
  if [ "$state" != "$1" ]; then
    errcho "state='$1', got '$state', is someone trying to hack you?"
    exit 1
  fi
  echo "$req" | grep -o 'access_token=.*' | awk -F '[=&]' '{ print $2 }'
}

serve_string() {
  for line in \
    'HTTP/1.1 200 OK' \
    "Content-Length: ${#1}" \
    'Connection: close' \
    ''
  do
    printf '%s\r\n' "$line"
  done
  echo "$1"
}

auth() {
  [ -f config.sh ] && return
  for p in nc curl; do
    if ! stfu command -v "$p"; then
      echo "$p was not found, please install it"
      exit 1
    fi
  done
  if ! curl -V | grep -q https; then
    echo "curl https support is missing, please rebuild your curl with https"
    exit 1
  fi
  echo "you need to authorize shigebot on the twitch account you want"
  echo "to run the bot from. make sure you are on a machine that has"
  echo "a web browser and confirm"
  echo
  printf "proceed with the authorization (y/N)?: "
  read -r answer
  if [ "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" != "y" ]; then
    echo "canceled"
    exit 0
  fi
  serve_string '
<html>
<head>
<script type="text/javascript">
window.location.href = "http://localhost:8070/?" +
window.location.hash.substr(1);
</script>
</head>
<body>
authorizing...
</body>
</html>' | nc -l -p 8069 | consume_request &
  state="$(od -vAn -N4 -tu4 < /dev/urandom | tr -d '[:space:]')"
  authfile="$(mktemp)"
  trap 'rm -rf "$authfile"; kill 0; exit' INT EXIT
  serve_string "authorized, shigebot should now run" |
    nc -l -p 8070 | consume_request_get_token "$state" >"$authfile" &
  authpid=$!
  auth_url="https://id.twitch.tv/oauth2/authorize"
  auth_url="${auth_url}?client_id=$client_id"
  auth_url="${auth_url}&redirect_uri=http://localhost:8069"
  auth_url="${auth_url}&response_type=token"
  auth_url="${auth_url}&scope=chat:read chat:edit"
  auth_url="${auth_url}&force_verify=true"
  auth_url="${auth_url}&state=$state"
  urlopen "$auth_url"
  wait $authpid || exit
  oauth="$(cat <"$authfile")"
  echo "which channels should the bot join?"
  printf "(space separated, you can edit this later): "
  read -r channels
  user="$(api / user_name)"
  cat >config.sh << EOF
#!/bin/sh
export user=$user
export oauth=$oauth
# channel n_messages n_seconds interval_seconds
# will send a maximum of n_messages every n_seconds to channel with a
# minimum interval of interval_seconds between each message
export channels="
EOF
  for c in $channels; do
    echo "$c 20 30 1" >>config.sh
  done
  echo '"' >>config.sh
  chmod +x config.sh
  echo "config.sh successfully generated, edit it for further tweaks"
  echo "NOTE: don't share your config.sh without censoring oauth"
  echo
}

api() {
  curl -sH 'Accept: application/vnd.twitchtv.v5+json' \
    -H "Client-ID: $client_id" \
    -H "Authorization: OAuth $oauth" \
    -X GET "https://api.twitch.tv/kraken$1" |
  grep -o "$2.*," |
  awk -F '[:,"]' '{ print $4 }' || exit
}

handle_recv() {
  touch "$activity_file"
  while read -r rl; do
    touch "$activity_file"
    echo "$rl" | sed 's/^[^:]/: &/'
  done
}

handle_send() {
  i=0
  firstmsg="$(date +%s)"
  channel_line="$(echo "$channels" | grep "$channel" | sed 1q)"
  ratelimit_messages="$(echo "$channel_line" | awk '{ print $2 }')"
  ratelimit_seconds="$(echo "$channel_line" | awk '{ print $3 }')"
  message_delay="$(echo "$channel_line" | awk '{ print $4 }')"
  while read -r sl; do
    errcho "[$(date '+%F %T') $module] $sl"
    if echo "$sl" | grep -q '^PRIVMSG'; then
      if [ "$i" -ge "$ratelimit_messages" ]; then
        errcho "(waiting on rate limiter)"
        while true; do
          now="$(date +%s)"
          elapsed=$(( now - firstmsg ))
          if [ "$elapsed" -gt "$ratelimit_seconds" ]; then
            break
          fi
          sleep 1
        done
        errcho "$channel: $i messages in $elapsed seconds"
        i=0
        firstmsg="$(date +%s)"
      fi
      add_invisible_char=$(( i % 2 ))
      suffix=""
      if [ "$add_invisible_char" = "1" ]; then
        suffix="$(printf '\xe2\x81\xa3')"
      fi
      i=$(( i + 1 ))
      printf '%s' "$sl" |
        awk -v suf="$suffix" '{ printf "%s%s\r\n", $0, suf }'
      sleep "$message_delay"
    else
      printf '%s' "$sl" | awk '{ printf "%s\r\n", $0 }'
    fi
  done
}

connect() {
  errcho "starting $module"
  echo "PASS oauth:$oauth"
  echo "NICK $user"
  echo "JOIN #$channel"
  handle_recv | "$module" "$channel" | handle_send
}

start_handler() {
  bname="$(basename "$module")_$channel"
  fifo="$tmpdir/$bname.fifo"
  activity_file="$tmpdir/$bname.activity"
  mkfifo "$fifo"
  while true; do
    touch "$activity_file"
    # shellcheck disable=SC2094
    openssl s_client -quiet -ign_eof -connect "$irc_server" <"$fifo" |
      connect >"$fifo" &
    pid=$!
    while true; do
      activity=$(stat -c %Y "$activity_file")
      now="$(date +%s)"
      since=$(( now - activity ))
      if [ $since -gt 300 ]; then
        echo "connection seems to be dead, restarting $module"
        kill -9 $pid
        break
      fi
      sleep 1
    done
  done
}

run() {
  auth
  . ./config.sh
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"; kill 0; exit' INT EXIT
  for module in "${@:-handlers}"/*; do
    if [ -x "$module" ]; then
      for channel in $(echo "$channels" | awk '{ print $1 }'); do
        start_handler &
      done
    fi
  done
  oauth="ayylmaooooooooooooooooooooooooooooo"
  unset $oauth
  while true; do
    sleep 1
  done
}

dir=$(dirname "$0")
wdir=$(realpath "$dir")
olddir="$(pwd)"
cd "$wdir" || exit
run "$@"
cd "$olddir" || exit
