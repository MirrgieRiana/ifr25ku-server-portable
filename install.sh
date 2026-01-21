#!/usr/bin/env bash

set -eu
type wget > /dev/null
type java > /dev/null
type tar > /dev/null
type unzip > /dev/null

(($# == 1)) || {
  echo "Usage: $0 <dir>" >&2
  exit
}
dir=$1

# Make directory
mkdir "$dir"
cd "$dir"

# Get Xarpite
wget "https://repo1.maven.org/maven2/io/github/mirrgieriana/xarpite-bin/4.93.1/xarpite-bin-4.93.1-all.tar.gz"
mkdir ./xarpite
tar -xzf xarpite-bin-4.93.1-all.tar.gz -C ./xarpite

# Get NeoForge and initialize server
wget "https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.217/neoforge-21.1.217-installer.jar"
mkdir server
(cd server; java -jar ../neoforge-21.1.217-installer.jar --install-server)

# Configure server
cat server/user_jvm_args.txt | grep -vE '^[ \t]*#' | grep -E -- '-Xmx4G\b' > /dev/null || {
  echo "" >> server/user_jvm_args.txt
  echo "-Xmx4G" >> server/user_jvm_args.txt
}

# Get Modpack
wget "https://cdn.modrinth.com/data/Mk6QNSrA/versions/emwVcPv1/IFR25KU%20Server%202026.1.7.mrpack"
unzip 'IFR25KU Server 2026.1.7.mrpack' -d modpack
chmod -R a+r modpack

# Install mods to server
cat modpack/modrinth.index.json | ./xarpite/xa 'IN.$*.files().downloads() | EXEC("wget", _, "-P", "server/mods")'

# Install Petrol's Parts
wget https://cdn.modrinth.com/data/AN0CZD9P/versions/uI6g3SiQ/petrolsparts-1.21.1-1.2.7.jar -P server/mods
wget https://cdn.modrinth.com/data/ik2WZkTZ/versions/oAqMSjdK/petrolpark-1.21.1-1.4.25.jar -P server/mods

echo "Success"
