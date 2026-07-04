#!/bin/sh
# Corretor ortografico. Roda o hunspell em modo LaTeX (-t) sobre cada arquivo
# .tex, reportando as palavras desconhecidas por arquivo. Verifica todos os
# arquivos antes de decidir o resultado: se algum tiver erros, falha (exit 1)
# ao final, depois de ter listado tudo.
#
# O hunspell em modo LaTeX (-t) pula \verb e ambientes verbatim conhecidos, mas
# NAO conhece o pacote minted: sem tratamento, todo o codigo dentro de blocos
# \begin{minted}...\end{minted} viraria "erro de ortografia". Por isso esses
# blocos sao removidos (via awk) antes de passar o texto ao hunspell.
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

# Remove os blocos de codigo do minted (inclusive as linhas \begin/\end) para
# que o hunspell nao tente corrigir o conteudo das listagens.
strip_minted() {
  awk '
    /\\begin\{minted\}/ { skip = 1 }
    !skip               { print }
    /\\end\{minted\}/   { skip = 0 }
  ' "$1"
}

status=0
for f in "$@"; do
  words=$(strip_minted "$f" | hunspell -t -l -i utf-8 -d "$lang" -p "$dict" | sort -u)
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
