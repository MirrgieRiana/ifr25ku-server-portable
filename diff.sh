#!/usr/bin/env bash

[ -f MODRINTH_MINECRAFT_DIR ] || {
  echo "MODRINTH_MINECRAFT_DIR is not supplied" 2>&1
  exit 1
}
new=$(cat MODRINTH_MINECRAFT_DIR)

diff -U0 <(ls -1 "tmp1/server/mods") <(ls -1 "$new/mods") | grep -vE '^(@@|---|\+\+\+) '
