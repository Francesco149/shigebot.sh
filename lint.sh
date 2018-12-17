#!/bin/sh

dir=$(dirname "$0")
wdir=$(realpath "$dir")
olddir="$(pwd)"
cd "$wdir" || exit
find . -name '*.sh' -print0 | xargs -0 shellcheck
cd "$olddir" || exit
