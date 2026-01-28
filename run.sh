#!/usr/bin/env bash

(($# == 1)) || {
  echo "Usage: $0 <dir>" >&2
  exit
}
dir=$1

cd "$dir/server" || exit
exec ./run.sh -nogui
