#!/bin/sh
# Remove os artefatos de build (build/) e o PDF final (output/).
#
# Uso: cleanall.sh <build_dir> <out_dir>
set -eu

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <build_dir> <out_dir>" >&2
  exit 2
fi
build_dir="$1"
out_dir="$2"
dir=$(dirname "$0")

"$dir/clean.sh" "$build_dir"
rm -rf "${out_dir:?}/"
