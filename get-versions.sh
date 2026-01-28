#!/usr/bin/env bash

./xarpite/xa '
  @USE("./maven/io/github/mirrgieriana/modrinth-client/0.0.1/modrinth-client-0.0.1.xa1")
  getProjectVersions(READ("SERVER_MODPACK_PROJECT_ID").&)().version_number
'
