#!/bin/sh
# Roda o linter LaTeX (chktex) sobre os arquivos de conteudo (.tex). Numa unica
# invocacao, para que o chktex veja todos os arquivos de uma vez.
#
# Uso: lint.sh <build_dir> <out_dir>
set -eu

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <build_dir> <out_dir>" >&2
  exit 2
fi
build_dir="$1"
out_dir="$2"
dir=$(dirname "$0")

# Coleta os arquivos nos parametros posicionais para passa-los de uma vez ao chktex.
files=$("$dir/find-sources.sh" lint "$build_dir" "$out_dir")
set --
while IFS= read -r f; do
  set -- "$@" "$f"
done <<EOF
$files
EOF

chktex -q "$@"
