twitch irc bot and irc-ifier in sh

![](https://i.imgur.com/7jWcjia.gif)

# requirements
you most likely already have all of this out of the box on linux
* sh or bash: tested on dash and busybox ash
* netcat: only for authentication, should work with all nc variants
* curl with https support: only for authentication
* mkfifo
* openssl or libressl: tested on libressl

# features
* automatic config/auth: if ```config.sh``` is not present, it will prompt
  you to log into twitch and automatically grab a new oauth token.
  if you need to run the bot on a headless machine, you should
  generate your config from a desktop first and then copy it over.
  javascript is required to extract the oauth token from the hash part
  of the url
* per-channel rate limits to avoid global ban
* auto-reconnect: if no pings or other activity are received in over 5
  minutes, the bot will attempt to restart the openssl client
* ircify programs written in any language: just drop an executable in
  the ```handlers``` directory: irc output will be piped into standard
  input while standard output will be piped back to irc. the channel name
  is passed as a command line argument and one process per channel is
  started. check out the examples that are already in the directory.

# install and usage
```sh
curl -L https://github.com/Francesco149/shigebot.sh/archive/master.tar.gz \
  > shigebot.sh-master.tar.gz
tar xf shigebot.sh-master.tar.gz
cd shigebot.sh-master
./shigebot.sh
```

once the configuration process is complete, do NOT share your config.sh
with other people as it contains your precious OAuth token
