#!/usr/bin/env bash

(($# == 1)) || {
  echo "Usage: $0 <dir>" >&2
  exit
}
dir=$1

[ -f MODRINTH_MINECRAFT_DIR ] || {
  echo "MODRINTH_MINECRAFT_DIR is not supplied" 2>&1
  exit 1
}
new=$(cat MODRINTH_MINECRAFT_DIR)

diff -U0 <(ls -1 "$dir/server/mods") <(ls -1 "$new/mods") | grep -vE '^(@@|---|\+\+\+) '
