#!/bin/sh
# Descoberta de arquivos fonte do projeto. Imprime, um por linha, os arquivos de
# uma dada categoria, ignorando os diretorios de build/output (e, no caso da
# ortografia, as listagens de codigo). Inclui arquivos novos ainda nao commitados.
#
# Centraliza os 'find' para que os scripts de format/lint/spell compartilhem a
# mesma descoberta.
#
# Uso: find-sources.sh <categoria> <build_dir> <out_dir>
#   format  arquivos fonte para o latexindent (.tex, .sty, .cls, .bib)
#   lint    arquivos .tex para o chktex
#   spell   arquivos .tex para o hunspell (exclui as listagens em */res/code/)
set -eu

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <format|lint|spell> <build_dir> <out_dir>" >&2
  exit 2
fi

category="$1"
build_dir="$2"
out_dir="$3"

case "$category" in
  format)
    # Arquivos fonte (.tex/.sty/.cls/.bib) para a formatacao com latexindent.
    find . \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.bib' \) \
      ! -path "./$build_dir/*" ! -path "./$out_dir/*"
    ;;
  lint)
    # Apenas .tex para o linter (chktex); .sty/.cls/.bib so gerariam ruido.
    find . -name '*.tex' \
      ! -path "./$build_dir/*" ! -path "./$out_dir/*"
    ;;
  spell)
    # .tex de prosa para o corretor ortografico; as listagens (content/*/res/code/)
    # ficam de fora porque sao codigo, nao texto.
    find . -name '*.tex' \
      ! -path "./$build_dir/*" ! -path "./$out_dir/*" ! -path '*/res/code/*'
    ;;
  *)
    echo "Categoria invalida: $category (use format, lint ou spell)" >&2
    exit 2
    ;;
esac
