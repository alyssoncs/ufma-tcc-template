#!/usr/bin/env bats
# Testes do scripts/main/spell.sh: remocao dos blocos minted, deduplicacao das
# palavras desconhecidas, uso do dicionario do projeto e codigos de saida.

setup() {
  load 'test_helper/common'
  _common_setup
}

@test "spell: remove blocos minted e deduplica as desconhecidas" {
  require_hunspell

  run "$MAIN/spell.sh" pt_BR,en_US /dev/null "$FIXTURES/spell/with-minted.tex"

  assert_failure 1
  # A prosa e reportada (e so uma vez, apesar de aparecer duas vezes no .tex).
  assert_line --partial 'zzdeadbeefzz'
  assert_equal "$(printf '%s\n' "$output" | grep -c 'zzdeadbeefzz')" 1
  # O conteudo dentro do bloco minted NAO pode ser reportado.
  refute_output --partial 'zzmintedonlyzz'
}

@test "spell: o dicionario do projeto exclui termos validos" {
  require_hunspell

  run "$MAIN/spell.sh" pt_BR,en_US "$FIXTURES/spell/dictionary.txt" \
    "$FIXTURES/spell/with-minted.tex"

  assert_failure 1
  assert_output --partial 'zzdeadbeefzz'
  # zzdictwordzz esta no dicionario, entao nao pode aparecer.
  refute_output --partial 'zzdictwordzz'
}

@test "spell: passa (exit 0) quando o dicionario cobre todas as desconhecidas" {
  require_hunspell

  run "$MAIN/spell.sh" pt_BR,en_US "$FIXTURES/spell/dictionary.txt" \
    "$FIXTURES/spell/covered.tex"

  assert_success
  assert_output ''
}

@test "spell: falha de uso (exit 2) com poucos argumentos" {
  run "$MAIN/spell.sh" pt_BR,en_US
  assert_failure 2
  assert_output --partial 'Uso:'
}

@test "spell: processa todos os arquivos antes de decidir (verifica todos)" {
  require_hunspell

  # O arquivo limpo vem PRIMEIRO; o script deve continuar e reportar o segundo.
  run "$MAIN/spell.sh" pt_BR,en_US /dev/null \
    "$FIXTURES/spell/clean.tex" "$FIXTURES/spell/with-error.tex"

  assert_failure 1
  assert_output --partial 'with-error.tex =='
  assert_output --partial 'zzdeadbeefzz'
}

@test "spell: remove multiplos blocos minted, inclusive um no fim do arquivo" {
  require_hunspell

  run "$MAIN/spell.sh" pt_BR,en_US /dev/null "$FIXTURES/spell/multi-minted.tex"

  assert_failure 1
  # A prosa e reportada...
  assert_output --partial 'zzdeadbeefzz'
  # ...e nenhum conteudo dos dois blocos minted aparece.
  refute_output --partial 'zzblocoumzz'
  refute_output --partial 'zzblocodoiszz'
}
