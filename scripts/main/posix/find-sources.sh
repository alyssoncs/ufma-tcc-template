#!/bin/sh
# Descoberta de arquivos fonte do projeto. Imprime, um por linha, os arquivos de
# uma dada categoria, ignorando os diretorios de build/output (e, no caso da
# ortografia, as listagens de codigo). Inclui arquivos novos ainda nao commitados.
#
# Centraliza os 'find' para que os scripts de format/lint/spell compartilhem a
# mesma descoberta.
#
# A varredura parte de <root>; build_dir/out_dir sao interpretados relativos a
# ela. O diretorio scripts/ fica de fora de todas as categorias.
#
# Uso: find-sources.sh <root> <categoria> <build_dir> <out_dir>
#   root      diretorio raiz da varredura (ex.: '.')
#   categoria format|lint|spell
#   format    arquivos fonte para o latexindent (.tex, .sty, .cls, .bib)
#   lint      arquivos .tex para o chktex
#   spell     arquivos .tex para o hunspell (exclui as listagens em */res/code/)
set -eu

if [ "$#" -ne 4 ]; then
  echo "Uso: $0 <root> <format|lint|spell> <build_dir> <out_dir>" >&2
  exit 2
fi

root="$1"
category="$2"
build_dir="$3"
out_dir="$4"

# Remove uma eventual barra final para nao gerar '//' nos padroes de -path.
root="${root%/}"

case "$category" in
  format)
    # Arquivos fonte (.tex/.sty/.cls/.bib) para a formatacao com latexindent.
    find "$root" \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.bib' \) \
      ! -path "$root/$build_dir/*" ! -path "$root/$out_dir/*" ! -path "$root/scripts/*"
    ;;
  lint)
    # Apenas .tex para o linter (chktex); .sty/.cls/.bib so gerariam ruido.
    find "$root" -name '*.tex' \
      ! -path "$root/$build_dir/*" ! -path "$root/$out_dir/*" ! -path "$root/scripts/*"
    ;;
  spell)
    # .tex de prosa para o corretor ortografico; as listagens (*/res/code/)
    # ficam de fora porque sao codigo, nao texto.
    find "$root" -name '*.tex' \
      ! -path "$root/$build_dir/*" ! -path "$root/$out_dir/*" ! -path "$root/scripts/*" \
      ! -path '*/res/code/*'
    ;;
  *)
    echo "Categoria invalida: $category (use format, lint ou spell)" >&2
    exit 2
    ;;
esac
