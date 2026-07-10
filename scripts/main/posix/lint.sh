#!/bin/sh
# Roda o linter LaTeX (chktex) sobre os arquivos de conteudo (.tex). Numa unica
# invocacao, para que o chktex veja todos os arquivos de uma vez. O arquivo de
# configuracao e passado explicitamente ao chktex (-l), para que suas opcoes
# valham em qualquer plataforma, sem depender de o chktex auto-descobri-lo pelo
# nome/diretorio atual.
#
# Uso: lint.sh <root> <config> <build_dir> <out_dir>
set -eu

if [ "$#" -ne 4 ]; then
  echo "Uso: $0 <root> <config> <build_dir> <out_dir>" >&2
  exit 2
fi
root="$1"
config="$2"
build_dir="$3"
out_dir="$4"
dir=$(dirname "$0")

# Coleta os arquivos nos parametros posicionais para passa-los de uma vez ao chktex.
files=$("$dir/find-sources.sh" "$root" lint "$build_dir" "$out_dir")
set --
while IFS= read -r f; do
  [ -n "$f" ] && set -- "$@" "$f"
done <<EOF
$files
EOF

# Sem arquivos para lintar: sai limpo (nao chama o chktex sem argumentos, o que
# o faria ler do stdin e travar).
[ "$#" -eq 0 ] && exit 0

chktex -q -l "$config" "$@"
