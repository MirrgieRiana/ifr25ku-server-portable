#!/usr/bin/env bash

set -eu
cd -- "$(dirname -- "$0")"
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
if [ ! -e xarpite ]; then
  wget "https://repo1.maven.org/maven2/io/github/mirrgieriana/xarpite-bin/4.93.1/xarpite-bin-4.93.1-all.tar.gz"
  mkdir ./xarpite
  tar -xzf xarpite-bin-4.93.1-all.tar.gz -C ./xarpite
fi

# Get NeoForge and initialize server
if [ ! -e neoforge-21.1.217-installer.jar ]; then
  wget "https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.217/neoforge-21.1.217-installer.jar"
fi
if [ ! -e server ]; then
  mkdir server
  (cd server; java -jar ../neoforge-21.1.217-installer.jar --install-server)
fi

# Configure server
cat server/user_jvm_args.txt | grep -vE '^[ \t]*#' | grep -E -- '-Xmx4G\b' > /dev/null || {
  echo "" >> server/user_jvm_args.txt
  echo "-Xmx4G" >> server/user_jvm_args.txt
}

./xarpite/xa -q '
  @USE("./../maven/io/github/mirrgieriana/modrinth-client/0.0.1/modrinth-client-0.0.1.xa1")

  serverModpackProjectId     := "ifr25ku-server-2509"
  serverModpackVersionNumber := "2026.1.24"

  # Get Modpack
  file := getProjectVersions(serverModpackProjectId)()
    >> FILTER [ _ => _.version_number == serverModpackVersionNumber ]
    | _.files()
    >> FILTER [ _ => _.primary ]
    >> SINGLE
  EXEC("wget", "-nv", file.url)
  EXEC("unzip", file.filename, "-d", "modpack")
  EXEC("chmod", "-R", "a+r", "modpack")

  # Install mods to server
  READ("modpack/modrinth.index.json").&.$*.files().downloads() | url => (
    EXEC("wget", "-nv", url, "-P", "server/mods")
  )

'

echo "Success"
