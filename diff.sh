#!/usr/bin/env bash

(($# == 1)) || {
  echo "Usage: $0 <target_dir>" >&2
  exit 1
}
target_dir=$1

[ -f MODRINTH_MINECRAFT_DIR ] || {
  echo "MODRINTH_MINECRAFT_DIR is not supplied" >&2
  exit 1
}
new=$(cat MODRINTH_MINECRAFT_DIR)

diff -U0 <(ls -1 "$target_dir/mods") <(ls -1 "$new/mods") | grep -vE '^(@@|---|\+\+\+) '
