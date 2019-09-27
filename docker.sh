#!/bin/sh

dir=$(dirname "$0")
wdir=$(realpath "$dir")
olddir="$(pwd)"
cd "$wdir" || exit
mkdir logs.mrkdb.d >/dev/null 2>&1
mkdir tweet_cache >/dev/null 2>&1
mkdir urban_cache >/dev/null 2>&1
docker build -t shigebot . &&
  docker run --rm \
    --volume "$wdir/logs.txt":/logs.txt \
    --volume "$wdir/quotes.txt":/quotes.txt \
    --volume "$wdir/logs99.time":/logs99.time \
    --volume "$wdir/logs.mrkdb.d":/logs.mrkdb.d \
    --volume "$wdir/tweet_cache":/tweet_cache \
    --volume "$wdir/urban_cache":/urban_cache \
    "$@" shigebot
cd "$olddir" || exit
