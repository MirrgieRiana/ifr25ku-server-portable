#!/usr/bin/env bash

[ -f MODRINTH_MINECRAFT_DIR ] || {
  echo "MODRINTH_MINECRAFT_DIR is not supplied" 2>&1
  exit 1
}
new=$(cat MODRINTH_MINECRAFT_DIR)

rsync -a --delete -v "$new/mods/" "tmp1/server/mods/"
