#!/bin/sh
# Verifica a formatacao dos arquivos fonte sem alterá-los. Falha (exit 1) assim
# que encontra um arquivo que precisaria ser reformatado pelo latexindent.
#
# Uso: format-check.sh <build_dir> <out_dir>
set -eu

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <build_dir> <out_dir>" >&2
  exit 2
fi
build_dir="$1"
out_dir="$2"
dir=$(dirname "$0")

"$dir/find-sources.sh" format "$build_dir" "$out_dir" | while IFS= read -r f; do
  if ! latexindent -k -s -l -m -c "$build_dir/" "$f"; then
    echo "Fora de formatacao: $f (rode 'just format')" >&2
    exit 1
  fi
done
