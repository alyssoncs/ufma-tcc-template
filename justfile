# Diretorios do latexmk (devem espelhar $aux_dir/$out_dir do .latexmkrc).
BUILD_DIR := "build"
OUT_DIR := "output"

# O just no Windows nao usa pwsh por padrao; os checks sao PowerShell 7.
set windows-shell := ["pwsh", "-NoProfile", "-Command"]

# Launcher do Python por SO: no Windows e `python` (o alias `python3` costuma
# apontar para o stub da Microsoft Store e falhar); no unix e `python3`.
PYTHON := if os() == "windows" { "python" } else { "python3" }

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
    ./scripts/main/posix/format.sh . {{ BUILD_DIR }} {{ OUT_DIR }}

[windows]
format:
    ./scripts/main/windows/format.ps1 . {{ BUILD_DIR }} {{ OUT_DIR }}

# Verifica a formatacao sem alterar (falha se houver pendencia).
[unix]
format-check:
    ./scripts/main/posix/format-check.sh . {{ BUILD_DIR }} {{ OUT_DIR }}

[windows]
format-check:
    ./scripts/main/windows/format-check.ps1 . {{ BUILD_DIR }} {{ OUT_DIR }}

# Roda o linter LaTeX (chktex) nos arquivos de conteudo.
[unix]
lint:
    ./scripts/main/posix/lint.sh . .chktexrc {{ BUILD_DIR }} {{ OUT_DIR }}

[windows]
lint:
    ./scripts/main/windows/lint.ps1 . .chktexrc {{ BUILD_DIR }} {{ OUT_DIR }}

# Roda o corretor ortografico (hunspell) nos arquivos de conteudo.
[unix]
spell:
    ./scripts/main/posix/spell.sh {{ SPELL_LANG }} {{ SPELL_DICT }} $(./scripts/main/posix/find-sources.sh . spell {{ BUILD_DIR }} {{ OUT_DIR }})

[windows]
spell:
    ./scripts/main/windows/spell.ps1 {{ SPELL_LANG }} {{ SPELL_DICT }} (./scripts/main/windows/find-sources.ps1 . spell {{ BUILD_DIR }} {{ OUT_DIR }})

# Valida tudo (format-check, lint e spell) sem compilar.
check: format-check lint spell

# Pipeline completo: valida (check) e compila o PDF.
build: check pdf

# Roda a verificacao dos scripts: shellcheck (analise estatica) + suite pytest.
# Standalone: NAO entra em check/build --- e para quem MANTEM o template, nao
# para quem escreve a monografia. Requer as deps do pytest
# (scripts/test/requirements.txt).
[unix]
test:
    shellcheck --shell=sh scripts/main/posix/*.sh
    {{ PYTHON }} -m pytest scripts/test

# No Windows so a suite pytest (o PSScriptAnalyzer --- analogo do shellcheck ---
# entra em slice propria).
[windows]
test:
    {{ PYTHON }} -m pytest scripts/test

# Remove os artefatos de build (build/).
[unix]
clean:
    ./scripts/main/posix/clean.sh {{ BUILD_DIR }}

[windows]
clean:
    ./scripts/main/windows/clean.ps1 {{ BUILD_DIR }}

# Remove os artefatos de build e o PDF final (output/).
[unix]
cleanall:
    ./scripts/main/posix/cleanall.sh {{ BUILD_DIR }} {{ OUT_DIR }}

[windows]
cleanall:
    ./scripts/main/windows/cleanall.ps1 {{ BUILD_DIR }} {{ OUT_DIR }}

# Mostra esta ajuda com as recipes disponiveis.
help:
    @just --list
