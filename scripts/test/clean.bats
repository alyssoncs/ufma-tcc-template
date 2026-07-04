#!/usr/bin/env bats
# Testes de comportamento de scripts/main/clean.sh e cleanall.sh: removem os
# diretorios certos e, crucialmente, ABORTAM sem apagar nada quando recebem um
# argumento vazio (guarda ${var:?}). Esse guard e critico para o port PowerShell,
# onde 'Remove-Item -Recurse' com string vazia e perigoso.
#
# clean.sh roda 'latexmk -c', que num diretorio sem .tex sai com exit 10 e, sob
# 'set -eu', abortaria o script antes do 'rm -rf'. Por isso stubamos o latexmk.

setup() {
  load 'test_helper/common'
  _common_setup
  stub_latexmk

  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE"
  cd "$TREE" || return 1
}

@test "clean: remove o build_dir" {
  mkdir -p build
  echo x >build/f.aux
  run "$MAIN/clean.sh" build
  assert_success
  [ ! -e build ]
}

@test "cleanall: remove build_dir E out_dir (delega para clean.sh)" {
  mkdir -p build output
  echo x >build/f.aux
  echo y >output/monografia.pdf
  run "$MAIN/cleanall.sh" build output
  assert_success
  [ ! -e build ]
  [ ! -e output ]
}

@test "clean: argumento vazio aborta sem apagar (guard build_dir)" {
  echo keep >keepme.txt
  run "$MAIN/clean.sh" ""
  assert_failure
  # A falha e do guard ${build_dir:?} (mensagem cita a variavel), NAO do rm
  # recusando "/". Isso garante que o teste pega a remocao do guard.
  assert_output --partial 'build_dir'
  [ -e keepme.txt ]
}

@test "cleanall: out_dir vazio aborta no guard (preserva o output)" {
  mkdir -p output
  echo keep >output/monografia.pdf
  run "$MAIN/cleanall.sh" build ""
  assert_failure
  # A falha e do guard ${out_dir:?} (mensagem cita a variavel).
  assert_output --partial 'out_dir'
  # O output nao foi apagado.
  [ -e output/monografia.pdf ]
}
