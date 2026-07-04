#!/usr/bin/env bash
# Helper comum dos testes bats. Carrega as libs (submodules) e expoe os caminhos
# do repo, dos scripts (scripts/main) e das fixtures (scripts/fixtures).

_common_setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." >/dev/null 2>&1 && pwd)"
  export REPO_ROOT
  export MAIN="$REPO_ROOT/scripts/main"
  export FIXTURES="$REPO_ROOT/scripts/fixtures"
}

# A suite de testes e para quem mantem o template (nao para quem escreve a
# monografia): as ferramentas sao obrigatorias. Se faltar o hunspell ou os
# dicionarios pt_BR/en_US, o teste FALHA (nao pula) para a suite nao passar
# verde testando nada.
require_hunspell() {
  command -v hunspell >/dev/null 2>&1 || fail "hunspell nao instalado"
  hunspell -D 2>&1 | grep -q '/pt_BR' || fail "dicionario pt_BR ausente"
  hunspell -D 2>&1 | grep -q '/en_US' || fail "dicionario en_US ausente"
}

# Falha (nao pula) se o latexindent nao estiver disponivel (usado por format.sh e
# format-check.sh).
require_latexindent() {
  command -v latexindent >/dev/null 2>&1 || fail "latexindent nao instalado"
}

# Falha (nao pula) se o chktex nao estiver disponivel (usado por lint.sh).
require_chktex() {
  command -v chktex >/dev/null 2>&1 || fail "chktex nao instalado"
}

# Cria um stub de latexmk no PATH que sai 0, para os testes de clean/cleanall
# nao dependerem do latexmk real (que, num diretorio sem .tex, sai com exit 10 e
# abortaria clean.sh sob 'set -eu' antes do 'rm -rf'). Chame no setup() do teste.
stub_latexmk() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/bin/sh\nexit 0\n' >"$BATS_TEST_TMPDIR/bin/latexmk"
  chmod +x "$BATS_TEST_TMPDIR/bin/latexmk"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export PATH
}
