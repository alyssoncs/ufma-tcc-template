"""spell.sh: remocao dos blocos minted, deduplicacao das palavras
desconhecidas, uso do dicionario do projeto e codigos de saida.

O spell.sh e chamado direto com <lang> <dict> <arquivo.tex>..., usando as
fixtures de scripts/fixtures/spell.
"""

import os
import subprocess

import pytest
from helpers import (
    CURRENT_PLATFORM,
    FIXTURES,
    WINDOWS_MAIN,
    Platform,
    copy_fixture,
    require_hunspell,
)

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


def test_remove_argumentos_de_citacao(run_script):
    require_hunspell()
    # As chaves do biblatex (\cite, \textcite, ...) nao sao prosa e sao removidas
    # antes do hunspell. Necessario para paridade entre plataformas: o hunspell
    # novo (unix, 1.7.2) pula \textcite, mas o build antigo do Windows nao ---
    # sem isso, as chaves seriam marcadas so no Windows.
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "with-citation.tex")
    )
    assert result.returncode == 1
    # A prosa fora da citacao e reportada...
    assert "zzdeadbeefzz" in result.stdout
    # ...mas a chave de citacao (dentro de \textcite/\cite) NAO.
    assert "zzkeyonlyzz" not in result.stdout


def test_falha_se_dicionario_ausente(run_script):
    require_hunspell()
    # Regressao: com um dicionario do -d ausente, o hunspell segue so com os que
    # abriu e sai 0 (as vezes sem stderr), o que mascararia um idioma nao
    # verificado como sucesso. O preflight deve pegar isso e FALHAR (exit 3),
    # mesmo sobre um arquivo sem erros de ortografia.
    result = run_script(
        "spell",
        "pt_BR,zz_INEXISTENTE",
        os.devnull,
        str(SPELL / "clean.tex"),
    )
    assert result.returncode == 3
    assert "zz_INEXISTENTE" in result.stderr


def test_ingles_valido_e_aceito(run_script):
    require_hunspell()
    # Prova que o en_US foi realmente carregado (nao so o pt_BR): a fixture so
    # tem palavras inglesas validas que o pt_BR sozinho reprovaria. Se o en_US
    # nao carregasse, elas seriam reportadas e o exit seria 1.
    result = run_script(
        "spell", "pt_BR,en_US", os.devnull, str(SPELL / "english.tex")
    )
    assert result.returncode == 0
    assert result.stdout == ""


def test_ingles_valido_reprovado_so_com_pt_BR(run_script):
    require_hunspell()
    # Ancora a fixture english.tex: sem o en_US, suas palavras (inglesas) sao
    # desconhecidas. Garante que test_ingles_valido_e_aceito prova o carregamento
    # do en_US, e nao que as palavras ja seriam aceitas pelo pt_BR.
    result = run_script("spell", "pt_BR", os.devnull, str(SPELL / "english.tex"))
    assert result.returncode == 1
    assert "abstract" in result.stdout


@pytest.mark.skipif(
    CURRENT_PLATFORM is not Platform.WINDOWS,
    reason="reproduz o parsing de `pwsh -Command`, so relevante no Windows",
)
def test_lang_com_virgula_pelo_caminho_do_just():
    require_hunspell()
    # Regressao do bug real: o `just` roda a recipe via `pwsh -Command` (nao
    # `-File`), onde `pt_BR,en_US` SEM aspas e interpretado como ARRAY (operador
    # virgula). Sem tratamento, o array chega espalhado ao hunspell
    # (-d pt_BR en_US): so o pt_BR carrega e o en_US vira arquivo de entrada, o
    # que faz o hunspell imprimir "Can't open en_US." e sair ANTES de checar o
    # texto --- stdout vazio, status 0, FALSO VERDE. O harness padrao usa
    # `-File`, que passa strings literais e NAO reproduz isso.
    #
    # Usamos um arquivo com erro proposital (zzdeadbeefzz): so distingue fix de
    # bug se o hunspell realmente rodar. Corrigido -> exit 1 + a palavra
    # reportada; buggado -> exit 0 sem saida (o hunspell nem chegou a checar).
    script = WINDOWS_MAIN / "spell.ps1"
    with_error = SPELL / "with-error.tex"
    result = subprocess.run(
        [
            "pwsh",
            "-NoProfile",
            "-Command",
            f"& '{script}' pt_BR,en_US '{os.devnull}' '{with_error}'",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert "zzdeadbeefzz" in result.stdout
