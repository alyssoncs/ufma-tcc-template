#!/bin/sh
# Formata in-place todos os arquivos fonte do projeto com o latexindent.
# Backups e indent.log vao para <root>/<build_dir> (gitignored).
#
# Uso: format.sh <root> <build_dir> <out_dir>
set -eu

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <root> <build_dir> <out_dir>" >&2
  exit 2
fi
root="$1"
build_dir="$2"
out_dir="$3"
dir=$(dirname "$0")

"$dir/find-sources.sh" "$root" format "$build_dir" "$out_dir" | while IFS= read -r f; do
  latexindent -w -s -l -m -c "$root/$build_dir/" "$f"
done
