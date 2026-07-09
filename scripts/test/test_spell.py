"""spell.sh: remocao dos blocos minted, deduplicacao das palavras
desconhecidas, uso do dicionario do projeto e codigos de saida.

O spell.sh e chamado direto com <lang> <dict> <arquivo.tex>..., usando as
fixtures de scripts/fixtures/spell.
"""

import os
import subprocess

from helpers import FIXTURES, copy_fixture, require_hunspell

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


def test_mensagem_resumo_no_erro(run_script):
    require_hunspell()
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "with-minted.tex")
    )
    assert result.returncode == 1
    # Ao falhar, o spell orienta o usuario a corrigir ou adicionar ao dicionario.
    # (A ausencia dessa mensagem no sucesso ja e garantida por
    # test_passa_quando_dicionario_cobre, que exige stdout == "".)
    assert "Erros de ortografia encontrados" in result.stdout


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


def test_palavras_indentadas_com_dois_espacos(run_script):
    require_hunspell()
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "with-minted.tex")
    )
    assert result.returncode == 1
    # Cada palavra desconhecida e listada indentada por 2 espacos sob o header.
    assert "  zzdeadbeefzz" in result.stdout.splitlines()


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


def test_reporta_todos_os_arquivos_com_erro(run_script, tmp_path):
    require_hunspell()
    # Dois arquivos COM erro: apos setar status=1 no primeiro, o loop deve seguir
    # e reportar tambem o segundo (o caso [clean, with-error] so prova que nao
    # para num arquivo LIMPO, nao que continua depois de um erro).
    copy_fixture("spell/with-error.tex", tmp_path / "a.tex")
    copy_fixture("spell/with-error.tex", tmp_path / "b.tex")

    result = run_script(
        "spell",
        "pt_BR,en_US",
        os.devnull,
        str(tmp_path / "a.tex"),
        str(tmp_path / "b.tex"),
    )
    assert result.returncode == 1
    assert "a.tex ==" in result.stdout
    assert "b.tex ==" in result.stdout


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


# Dicionario de idioma que nao existe: forca o hunspell a sair com codigo != 0
# ("Can't open affix or dictionary files ...") ANTES de ler o texto, deixando o
# stdout vazio.
_MISSING_LANG = "zz_ZZ_nao_existe"


def test_falha_do_hunspell_faz_bail_out(run_script):
    """Se o hunspell sair com codigo != 0 (aqui: dicionario inexistente), o
    script deve abortar (bail out) com o MESMO codigo de saida, em vez de tratar
    o stdout vazio como sucesso.

    Este teste FALHA de proposito enquanto o bug do falso verde existir:
    spell.sh/spell.ps1 decidem o status pela CONTAGEM de palavras desconhecidas
    (stdout) e ignoram o exit code do hunspell -- com 'set -eu' sem pipefail (sh)
    e sem checar $LASTEXITCODE (ps1), a falha do hunspell no meio do pipe (que o
    'sort'/'Sort-Object' final mascara) passa como exit 0. O teste so passa
    quando os scripts propagarem a falha do hunspell."""
    require_hunspell()

    # Exit code do proprio hunspell ao falhar com o dicionario inexistente.
    hunspell_rc = subprocess.run(
        ["hunspell", "-d", _MISSING_LANG, "-l"],
        input="teste\n",
        capture_output=True,
        text=True,
    ).returncode
    assert hunspell_rc != 0, "sanidade: o dicionario deveria mesmo faltar"

    # Mesmo com um arquivo que contem erro de ortografia, o resultado NAO deve
    # ser um falso verde: se o hunspell falhou, o script tem de falhar tambem.
    result = run_script(
        "spell", _MISSING_LANG, os.devnull, str(SPELL / "with-error.tex")
    )
    assert result.returncode == hunspell_rc
