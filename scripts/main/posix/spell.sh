#!/bin/sh
# Corretor ortografico. Roda o hunspell em modo LaTeX (-t) sobre cada arquivo
# .tex, reportando as palavras desconhecidas por arquivo. Verifica todos os
# arquivos antes de decidir o resultado: se algum tiver erros, falha (exit 1)
# ao final, depois de ter listado tudo.
#
# O hunspell em modo LaTeX (-t) pula \verb e ambientes verbatim conhecidos, mas
# NAO conhece o pacote minted: sem tratamento, todo o codigo dentro de blocos
# \begin{minted}...\end{minted} viraria "erro de ortografia". Por isso esses
# blocos --- e os argumentos de comandos de citacao (chaves do biblatex) --- sao
# removidos (via awk) antes de passar o texto ao hunspell.
#
# Antes de corrigir, valida que TODOS os dicionarios do hunspell carregam; se
# algum faltar, falha (exit 3) em vez de checar so parte dos idiomas em silencio.
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

# Garante que TODOS os dicionarios do hunspell carregam antes de corrigir. Um
# dicionario ausente/ilegivel faz o hunspell seguir so com os que abriu e sair 0
# --- as vezes sem nada no stderr ---, mascarando um idioma nao verificado como
# sucesso (falso verde). Checamos cada idioma isolado (o -d <lang> sozinho sai
# != 0 se nao achar os arquivos) e tambem o uso combinado (alguns builds abrem
# cada idioma isolado mas emitem "Can't open <lang>." no stderr no modo
# -d a,b). Falha (exit 3) se qualquer verificacao acusar dicionario faltando.
assert_dicts_load() {
  langs="$1"
  oldifs="$IFS"
  IFS=','
  for l in $langs; do
    if ! printf '' | hunspell -d "$l" -l >/dev/null 2>&1; then
      IFS="$oldifs"
      echo "Erro: o dicionario do hunspell '$l' nao pode ser carregado (-d $l)." >&2
      echo "Verifique a instalacao do dicionario e o DICPATH." >&2
      return 1
    fi
  done
  IFS="$oldifs"
  combined_err=$(printf '' | hunspell -d "$langs" -l 2>&1 >/dev/null) || true
  if printf '%s' "$combined_err" | grep -qi "can't open"; then
    echo "Erro: o hunspell nao carregou todos os dicionarios de '-d $langs':" >&2
    printf '%s\n' "$combined_err" | sed 's/^/  /' >&2
    return 1
  fi
}

if ! assert_dicts_load "$lang"; then
  exit 3
fi

# Prepara cada arquivo para o hunspell, removendo o que nao deve ser corrigido:
#   - blocos \begin{minted}...\end{minted} (codigo das listagens);
#   - argumentos de comandos de citacao (\cite, \textcite, \parencite, ...), que
#     sao chaves do biblatex, nao prosa. O hunspell so pula esses comandos nas
#     versoes novas (1.7.2); o build antigo do Windows (winget FSFhu, ~1.7.0) nao
#     conhece \textcite/\autocite e marcaria as chaves --- removemos aqui para
#     ficar consistente entre plataformas.
strip_for_hunspell() {
  awk '
    /\\begin\{minted\}/ { skip = 1 }
    !skip {
      line = $0
      gsub(/\\[[:alpha:]]*[Cc]ite[[:alpha:]]*\{[^{}]*\}/, " ", line)
      print line
    }
    /\\end\{minted\}/   { skip = 0 }
  ' "$1"
}

status=0
for f in "$@"; do
  words=$(strip_for_hunspell "$f" | hunspell -t -l -i utf-8 -d "$lang" -p "$dict" | sort -u)
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
