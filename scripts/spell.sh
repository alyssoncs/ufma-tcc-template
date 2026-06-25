#!/bin/sh
# Corretor ortografico. Roda o hunspell em modo LaTeX (-t) sobre cada arquivo
# .tex, reportando as palavras desconhecidas por arquivo. Verifica todos os
# arquivos antes de decidir o resultado: se algum tiver erros, falha (exit 1)
# ao final, depois de ter listado tudo.
#
# Uso: spell.sh <lang> <dict> <arquivo.tex>...
#   lang   dicionarios do hunspell (ex.: pt_BR,en_US)
#   dict   dicionario do projeto, palavras validas (ex.: dictionary.txt)
set -eu

if [ "$#" -lt 3 ]; then
  echo "Uso: $0 <lang> <dict> <arquivo.tex>..." >&2
  exit 2
fi

lang="$1"
dict="$2"
shift 2

status=0
for f in "$@"; do
  words=$(hunspell -t -l -i utf-8 -d "$lang" -p "$dict" "$f" | sort -u)
  if [ -n "$words" ]; then
    status=1
    echo "== $f =="
    echo "$words" | sed 's/^/  /'
  fi
done

if [ "$status" -ne 0 ]; then
  echo "Erros de ortografia encontrados. Corrija-os ou, se forem termos validos,"
  echo "adicione-os (1 por linha) em $dict."
fi
exit "$status"
