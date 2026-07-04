#!/usr/bin/env bats
# Testes de comportamento do scripts/main/lint.sh: exit 0 num .tex limpo, falha
# quando o chktex acha um problema, e passa TODOS os arquivos numa unica
# invocacao (o script monta os parametros posicionais a partir da descoberta --
# logica nao-trivial que o port PowerShell tera de replicar).
#
# A arvore e hermetica (sem .chktexrc) -> chktex usa os defaults. Usamos o aviso
# W26 (espaco antes de pontuacao), estavel entre versoes do chktex.

setup() {
  load 'test_helper/common'
  _common_setup
  require_chktex

  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE/build"
}

@test "lint: exit 0 em .tex limpo" {
  cp "$FIXTURES/lint/clean.tex" "$TREE/clean.tex"
  run "$MAIN/lint.sh" "$TREE" build output
  assert_success
}

@test "lint: falha quando o chktex encontra um aviso" {
  cp "$FIXTURES/lint/warning.tex" "$TREE/warn.tex"
  run "$MAIN/lint.sh" "$TREE" build output
  assert_failure
  assert_output --partial 'warn.tex'
}

@test "lint: passa todos os arquivos numa unica invocacao" {
  cp "$FIXTURES/lint/warning.tex" "$TREE/a.tex"
  cp "$FIXTURES/lint/warning.tex" "$TREE/b.tex"
  run "$MAIN/lint.sh" "$TREE" build output
  assert_failure
  # A saida menciona AMBOS os arquivos: prova que o loop montou os parametros
  # posicionais e passou tudo de uma vez ao chktex.
  assert_output --partial 'a.tex'
  assert_output --partial 'b.tex'
}
