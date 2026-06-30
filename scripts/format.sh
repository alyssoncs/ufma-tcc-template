#!/bin/sh
# Formata in-place todos os arquivos fonte do projeto com o latexindent.
# Backups e indent.log vao para build/ (gitignored).
#
# Uso: format.sh <build_dir> <out_dir>
set -eu

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <build_dir> <out_dir>" >&2
  exit 2
fi
build_dir="$1"
out_dir="$2"
dir=$(dirname "$0")

"$dir/find-sources.sh" format "$build_dir" "$out_dir" | while IFS= read -r f; do
  latexindent -w -s -l -m -c "$build_dir/" "$f"
done
