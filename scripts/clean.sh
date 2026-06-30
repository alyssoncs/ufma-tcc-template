#!/bin/sh
# Remove os artefatos de build (build/).
#
# Uso: clean.sh <build_dir>
set -eu

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <build_dir>" >&2
  exit 2
fi
build_dir="$1"

latexmk -c
rm -rf "${build_dir:?}/"
