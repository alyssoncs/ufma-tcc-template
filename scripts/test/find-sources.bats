#!/usr/bin/env bats
# Testes do scripts/main/find-sources.sh: descoberta de arquivos por categoria
# (format/lint/spell), exclusao de build/output e das listagens em */res/code/*,
# e validacao de categoria/uso. A arvore de teste e montada num diretorio
# temporario (nao depende da arvore real do repo).

setup() {
  load 'test_helper/common'
  _common_setup

  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE/content/x/res/code" "$TREE/build" "$TREE/output" \
    "$TREE/scripts/fixtures"
  : >"$TREE/a.tex"
  : >"$TREE/b.sty"
  : >"$TREE/c.cls"
  : >"$TREE/d.bib"
  : >"$TREE/notes.md"
  : >"$TREE/content/x/index.tex"
  : >"$TREE/content/x/res/code/snippet.tex"
  : >"$TREE/build/ignored.tex"
  : >"$TREE/output/ignored.tex"
  : >"$TREE/scripts/fixtures/ignored.tex"
}

# Roda o find-sources na arvore de teste passando-a como RAIZ (sem cd) e ordena a
# saida (a ordem do find depende do sistema de arquivos). Com a raiz explicita os
# caminhos vem como "$TREE/...".
run_sorted() {
  run "$MAIN/find-sources.sh" "$TREE" "$1" build output
  output="$(printf '%s\n' "$output" | sort)"
}

@test "find-sources format: .tex/.sty/.cls/.bib, fora de build/output" {
  run_sorted format
  assert_success
  expected="$(printf '%s\n' \
    "$TREE/a.tex" "$TREE/b.sty" "$TREE/c.cls" "$TREE/content/x/index.tex" \
    "$TREE/content/x/res/code/snippet.tex" "$TREE/d.bib" | sort)"
  assert_equal "$output" "$expected"
}

@test "find-sources lint: apenas .tex, fora de build/output (inclui res/code)" {
  run_sorted lint
  assert_success
  expected="$(printf '%s\n' \
    "$TREE/a.tex" "$TREE/content/x/index.tex" \
    "$TREE/content/x/res/code/snippet.tex" | sort)"
  assert_equal "$output" "$expected"
}

@test "find-sources spell: .tex exceto as listagens em */res/code/*" {
  run_sorted spell
  assert_success
  expected="$(printf '%s\n' "$TREE/a.tex" "$TREE/content/x/index.tex" | sort)"
  assert_equal "$output" "$expected"
}

@test "find-sources: categoria invalida falha (exit 2)" {
  run "$MAIN/find-sources.sh" "$TREE" naoexiste build output
  assert_failure 2
  assert_output --partial 'Categoria invalida'
}

@test "find-sources: numero errado de argumentos falha (exit 2)" {
  run "$MAIN/find-sources.sh" "$TREE" format
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "find-sources: saida vazia quando nada casa" {
  # Arvore so com um arquivo nao-fonte: nenhuma categoria deve encontrar nada.
  empty="$BATS_TEST_TMPDIR/empty"
  mkdir -p "$empty"
  : >"$empty/notes.md"

  run "$MAIN/find-sources.sh" "$empty" format build output
  assert_success
  assert_output ''
}
