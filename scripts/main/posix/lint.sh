#!/bin/sh
# Roda o linter LaTeX (chktex) sobre os arquivos de conteudo (.tex). Numa unica
# invocacao, para que o chktex veja todos os arquivos de uma vez.
#
# Uso: lint.sh <root> <build_dir> <out_dir>
set -eu

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <root> <build_dir> <out_dir>" >&2
  exit 2
fi
root="$1"
build_dir="$2"
out_dir="$3"
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

# Passa o .chktexrc do projeto explicitamente (-l, append ao global) quando ele
# existe: no Windows o chktex nao faz a busca automatica do .chktexrc no
# diretorio atual, e sem ele as supressoes (-n13/-n17/-n24) nao valeriam. Sem
# .chktexrc (ex.: arvores de teste hermeticas) usa os defaults do chktex.
if [ -f "$root/.chktexrc" ]; then
  chktex -q -l "$root/.chktexrc" "$@"
else
  chktex -q "$@"
fi
