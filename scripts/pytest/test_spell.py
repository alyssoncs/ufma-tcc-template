"""Porta spell.bats: remocao dos blocos minted, deduplicacao das palavras
desconhecidas, uso do dicionario do projeto e codigos de saida.

O spell.sh e chamado direto com <lang> <dict> <arquivo.tex>..., usando as
fixtures de scripts/fixtures/spell.
"""

import os

from helpers import FIXTURES, require_hunspell

SPELL = FIXTURES / "spell"


def test_remove_minted_e_deduplica(run_script):
    require_hunspell()
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "with-minted.tex")
    )
    assert result.returncode == 1
    # A prosa e reportada (e so uma vez, apesar de aparecer duas vezes no .tex).
    assert "zzdeadbeefzz" in result.stdout
    assert result.stdout.count("zzdeadbeefzz") == 1
    # O conteudo dentro do bloco minted NAO pode ser reportado.
    assert "zzmintedonlyzz" not in result.stdout


def test_dicionario_exclui_termos(run_script):
    require_hunspell()
    result = run_script(
        "spell",
        "pt_BR,en_US",
        str(SPELL / "dictionary.txt"),
        str(SPELL / "with-minted.tex"),
    )
    assert result.returncode == 1
    assert "zzdeadbeefzz" in result.stdout
    # zzdictwordzz esta no dicionario, entao nao pode aparecer.
    assert "zzdictwordzz" not in result.stdout


def test_passa_quando_dicionario_cobre(run_script):
    require_hunspell()
    result = run_script(
        "spell",
        "pt_BR,en_US",
        str(SPELL / "dictionary.txt"),
        str(SPELL / "covered.tex"),
    )
    assert result.returncode == 0
    assert result.stdout == ""


def test_uso_com_poucos_args(run_script):
    result = run_script("spell", "pt_BR,en_US")
    assert result.returncode == 2
    assert "Uso:" in result.stderr


def test_processa_todos_os_arquivos(run_script):
    require_hunspell()
    # O arquivo limpo vem PRIMEIRO; o script deve continuar e reportar o segundo.
    result = run_script(
        "spell",
        "pt_BR,en_US",
        os.devnull,
        str(SPELL / "clean.tex"),
        str(SPELL / "with-error.tex"),
    )
    assert result.returncode == 1
    assert "with-error.tex ==" in result.stdout
    assert "zzdeadbeefzz" in result.stdout


def test_remove_multiplos_blocos_minted(run_script):
    require_hunspell()
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "multi-minted.tex")
    )
    assert result.returncode == 1
    # A prosa e reportada...
    assert "zzdeadbeefzz" in result.stdout
    # ...e nenhum conteudo dos dois blocos minted aparece.
    assert "zzblocoumzz" not in result.stdout
    assert "zzblocodoiszz" not in result.stdout
