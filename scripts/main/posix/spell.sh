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
# Alem disso, as CHAVES de comandos de citacao/remissao (\cite, \textcite,
# \ref, \label, ...) sao identificadores do biblatex/LaTeX (ex.: "knuth:goto"),
# nao palavras. Versoes novas do hunspell (>=1.7.1) pulam esses comandos e seus
# argumentos no modo -t, mas a 1.7.0 (usada no job Windows do CI) NAO pula, e
# reporta os fragmentos da chave como erros. Para o resultado ser deterministico
# entre versoes, removemos os argumentos desses comandos aqui (via awk) antes de
# passar o texto ao hunspell -- do mesmo modo que fazemos com os blocos minted.
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

# Remove os argumentos dos comandos de citacao/remissao (\cite, \textcite,
# \ref, \label, ...). As chaves desses comandos sao identificadores do
# biblatex/LaTeX (ex.: "knuth:goto"), nao palavras -- versoes novas do hunspell
# (>=1.7.1) as pulam no modo -t, mas a 1.7.0 (job Windows do CI) NAO, e reporta
# os fragmentos da chave como erros. Removemos aqui o argumento obrigatorio
# ({...}), a variante estrela (\textcite*) e os argumentos opcionais ([...])
# para que o resultado seja deterministico entre versoes do hunspell.
strip_citations() {
  awk '
    {
      line = $0
      while (match(line, /\\(textcite|autocite|parencite|footcite|nocite|cite|autoref|pageref|eqref|ref|label)\*?[ \t]*(\[[^]]*\])*\{[^}]*\}/)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
      }
      print line
    }
  '
}

status=0
for f in "$@"; do
  hrc=0
  hunspell_out=$(strip_minted "$f" | strip_citations | hunspell -t -l -i utf-8 -d "$lang" -p "$dict") || hrc=$?
  if [ "$hrc" -ne 0 ]; then
    exit "$hrc"
  fi
  words=$(printf '%s\n' "$hunspell_out" | sort -u)
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
