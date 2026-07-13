#!/bin/sh
# Remove os artefatos de build (build/) e os caches de teste (__pycache__,
# .pytest_cache) gerados pela suite pytest sob scripts/.
#
# Uso: clean.sh <build_dir>
set -eu

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <build_dir>" >&2
  exit 2
fi
build_dir="$1"

latexmk -c
rm -rf "${build_dir:?}/"

# Remove os caches do Python/pytest (__pycache__, .pytest_cache) que a suite de
# testes gera sob scripts/. Sao regenerados a cada `just test`; limpa-los aqui
# evita lixo acumulado (ex.: .pyc de versoes diferentes do Python). Ausencia de
# scripts/ (ou de caches) nao e erro.
if [ -d scripts ]; then
  find scripts -type d \( -name '__pycache__' -o -name '.pytest_cache' \) \
    -prune -exec rm -rf {} +
fi
