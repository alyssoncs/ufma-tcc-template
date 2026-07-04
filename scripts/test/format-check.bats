#!/usr/bin/env bats
# Testes de comportamento do scripts/main/format-check.sh: falha (exit 1) quando
# ha arquivo desformatado, passa (exit 0) apos formatar (round-trip) e roteia a
# mensagem de erro para o stderr. Trava o contrato observavel antes do port p/
# PowerShell.
#
# Round-trip (formatar com o proprio script e entao checar) evita depender de um
# golden "formatado", que e fragil entre latexindent 3.x (local) e 4.x (CI).

bats_require_minimum_version 1.5.0

setup() {
  load 'test_helper/common'
  _common_setup
  require_latexindent

  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE/build"

  # Copia (nao referencia) o fixture: format reescreve in-place e a descoberta
  # exige o arquivo dentro de $TREE.
  cp "$FIXTURES/format/unformatted.tex" "$TREE/bad.tex"
}

@test "format-check: falha (exit 1) em arquivo desformatado" {
  run "$MAIN/format-check.sh" "$TREE" build output
  assert_failure 1
  assert_output --partial 'Fora de formatacao'
}

@test "format-check: passa (exit 0) apos format.sh (round-trip)" {
  run "$MAIN/format.sh" "$TREE" build output
  assert_success

  run "$MAIN/format-check.sh" "$TREE" build output
  assert_success
  assert_output ''
}

@test "format-check: mensagem de erro vai para o stderr, nao stdout" {
  run --separate-stderr "$MAIN/format-check.sh" "$TREE" build output
  assert_failure 1
  # stdout limpo; a mensagem fica no stderr (contrato importante para o port).
  assert_equal "$output" ''
  [[ "$stderr" == *'Fora de formatacao'* ]]
}
