#!/bin/sh

emotes="$(mktemp)"
curl -s https://api.betterttv.net/2/emotes | tr '"' '\n' > "$emotes"
pepes=$(sed -n '/^Feels.*$/p' < "$emotes")
holiday=$(sed -n '/^SoSnowy.*$/p' < "$emotes")
rm "$emotes"

echo "PRIVMSG #$1 :hello, I am online FeelsGoodMan"

pepe_pool() {
  echo "RarePepe" # 1/1000 chance
  yes "$pepes" | sed 999q
}

while read -r line; do
  irccmd="$(echo "$line" | awk '{ print $2 }')"
  case "$irccmd" in
  PING) echo "$line" | sed s/^PING/PONG/ ;;
  PRIVMSG) #:user!user@user.tmi.twitch.tv PRIVMSG #channel :text\r\n
    channel="$(echo "$line" | awk '{ printf $3 }')"
    message="$(echo "$line" | awk '{ printf $4 }' | tr -d '\r')"
    case "$message" in
      :!pepe)
        n="$(od -vAn -N2 -tu2 < /dev/urandom)"
        n=$(( n % 10001 ))
        n="$(printf "%03d" $n | sed 's/..$/.&/')"
        pepe="$(pepe_pool | shuf -n 1 --random-source=/dev/urandom)"
        echo "PRIVMSG $channel :$pepe $holiday [$n]"
        ;;
    esac
    ;;
  esac
done
