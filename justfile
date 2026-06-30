# Diretorios do latexmk (devem espelhar $aux_dir/$out_dir do .latexmkrc).
BUILD_DIR := "build"
OUT_DIR := "output"

# Idiomas do hunspell (dicionarios do SO). pt_BR + en_US porque a monografia tem
# resumo/abstract e citacoes em ingles. Sobrescreva com 'just SPELL_LANG=pt_BR spell'.
SPELL_LANG := "pt_BR,en_US"

# Dicionario do projeto: termos tecnicos e nomes proprios validos (1 por linha).
SPELL_DICT := "dictionary.txt"

# Recipe padrao: so compila o PDF (loop rapido de quem esta escrevendo).
pdf:
    latexmk

# Modo watch: recompila a cada alteracao (latexmk -pvc).
continuous:
    latexmk -pvc

# Formata todos os arquivos fonte in-place (latexindent).
[unix]
format:
    ./scripts/format.sh {{ BUILD_DIR }} {{ OUT_DIR }}

# Verifica a formatacao sem alterar (falha se houver pendencia).
[unix]
format-check:
    ./scripts/format-check.sh {{ BUILD_DIR }} {{ OUT_DIR }}

# Roda o linter LaTeX (chktex) nos arquivos de conteudo.
[unix]
lint:
    ./scripts/lint.sh {{ BUILD_DIR }} {{ OUT_DIR }}

# Roda o corretor ortografico (hunspell) nos arquivos de conteudo.
[unix]
spell:
    ./scripts/spell.sh {{ SPELL_LANG }} {{ SPELL_DICT }} $(./scripts/find-sources.sh spell {{ BUILD_DIR }} {{ OUT_DIR }})

# Valida tudo (format-check, lint e spell) sem compilar.
check: format-check lint spell

# Pipeline completo: valida (check) e compila o PDF.
build: check pdf

# Remove os artefatos de build (build/).
[unix]
clean:
    ./scripts/clean.sh {{ BUILD_DIR }}

# Remove os artefatos de build e o PDF final (output/).
[unix]
cleanall:
    ./scripts/cleanall.sh {{ BUILD_DIR }} {{ OUT_DIR }}

# Mostra esta ajuda com as recipes disponiveis.
help:
    @just --list
