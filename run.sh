#!/usr/bin/env bash

(($# == 1)) || {
  echo "Usage: $0 <target_dir>" >&2
  exit
}
target_dir=$1

cd "$target_dir" || exit
exec ./run.sh -nogui
