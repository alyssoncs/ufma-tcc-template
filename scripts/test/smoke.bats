#!/usr/bin/env bats
# Smoke tests: cada script de scripts/main rejeita uso incorreto (numero de
# argumentos invalido) com exit 2 e mensagem de uso. Cobre o contrato de CLI
# compartilhado por todos os scripts.

setup() {
  load 'test_helper/common'
  _common_setup
}

@test "format.sh: sem argumentos -> exit 2" {
  run "$MAIN/format.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "format-check.sh: sem argumentos -> exit 2" {
  run "$MAIN/format-check.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "lint.sh: sem argumentos -> exit 2" {
  run "$MAIN/lint.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "clean.sh: sem argumentos -> exit 2" {
  run "$MAIN/clean.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "cleanall.sh: sem argumentos -> exit 2" {
  run "$MAIN/cleanall.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "find-sources.sh: sem argumentos -> exit 2" {
  run "$MAIN/find-sources.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "spell.sh: sem argumentos -> exit 2" {
  run "$MAIN/spell.sh"
  assert_failure 2
  assert_output --partial 'Uso:'
}
