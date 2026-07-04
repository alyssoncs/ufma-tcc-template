#!/usr/bin/env bats
# Testes de comportamento do scripts/main/format.sh: reescreve os fontes in-place
# (deixando-os formatados) e roteia backups/log do latexindent para build/, sem
# sujar o diretorio do fonte. Contrato relevante para o port PowerShell.

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

@test "format: reescreve in-place e o resultado passa no format-check (round-trip)" {
  before="$(cat "$TREE/bad.tex")"

  run "$MAIN/format.sh" "$TREE" build output
  assert_success

  # O arquivo mudou (foi reformatado)...
  after="$(cat "$TREE/bad.tex")"
  [ "$before" != "$after" ]

  # ...e agora esta formatado segundo o proprio format-check.
  run "$MAIN/format-check.sh" "$TREE" build output
  assert_success
}

@test "format: backups/log vao para build/, nao sujam a arvore do fonte" {
  run "$MAIN/format.sh" "$TREE" build output
  assert_success

  # Nenhum backup do latexindent ao lado do fonte.
  run sh -c 'ls "'"$TREE"'"/*.bak* 2>/dev/null | wc -l'
  assert_output '0'

  # O backup e/ou o indent.log foram para build/.
  run sh -c 'ls "'"$TREE"'"/build/ | wc -l'
  refute_output '0'
}
