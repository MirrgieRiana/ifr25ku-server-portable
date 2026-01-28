#!/usr/bin/env bash

set -eu
cd -- "$(dirname -- "$0")"
type wget > /dev/null
type curl > /dev/null
type java > /dev/null
type unzip > /dev/null

(($# == 1)) || {
  echo "Usage: $0 <target_dir>" >&2
  exit 1
}
export target_dir="$1"

export workspace_dir="$(pwd)"
export build_dir="$workspace_dir/build"

# Make target directory
[ -e "$target_dir" ] && {
  echo "Already exists: $target_dir" >&2
  exit 1
}
mkdir -p "$target_dir"

# Get NeoForge
neoforge_version=21.1.217
neoforge_installer_filename=neoforge-$neoforge_version-installer.jar
neoforge_installer_dir="$build_dir"/neoforge-installer
neoforge_installer_path="$neoforge_installer_dir"/"$neoforge_installer_filename"
mkdir -p "$neoforge_installer_dir"
[ ! -e "$neoforge_installer_path" ] && {
  wget "https://maven.neoforged.net/releases/net/neoforged/neoforge/$neoforge_version/$neoforge_installer_filename" \
    -O "$neoforge_installer_path"
}

# Initialize server
(
  cd -- "$target_dir"
  java -jar "$neoforge_installer_path" --install-server
)

# Configure server
echo "" >> "$target_dir"/user_jvm_args.txt
echo "-Xmx4G" >> "$target_dir"/user_jvm_args.txt

./xarpite/xa -q '
  @USE("./maven/io/github/mirrgieriana/modrinth-client/0.0.1/modrinth-client-0.0.1.xa1")

  serverModpackProjectId     := READ("SERVER_MODPACK_PROJECT_ID").&
  serverModpackVersionNumber := READ("SERVER_MODPACK_VERSION").&

  # Get Modpack
  file := getProjectVersions(serverModpackProjectId)()
    >> FILTER [ _ => _.version_number == serverModpackVersionNumber ]
    | _.files()
    >> FILTER [ _ => _.primary ]
    >> SINGLE
  EXEC("mkdir", "-p", "$(ENV.build_dir)/modpacks")
  EXEC("wget", "-nv", file.url, "-P", "$(ENV.build_dir)/modpacks")

  # Install mods to server
  modpackData := EXEC("unzip", "-p", "$(ENV.build_dir)/modpacks/$(file.filename)", "modrinth.index.json").&.$*
  modpackData.files().downloads() | url => (
    EXEC("wget", "-nv", url, "-P", "$(ENV.target_dir)/mods")
  )

'

echo "Success"
