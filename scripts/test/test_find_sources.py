"""find-sources.sh: descoberta de arquivos por categoria
(format/lint/spell), exclusao de build/output/scripts e das listagens em
*/res/code/*, e validacao de categoria/uso. A arvore de teste e montada num
diretorio temporario (nao depende da arvore real do repo).
"""

import os
from pathlib import Path

import pytest

from helpers import make_files, sorted_lines

TREE_FILES = [
    "a.tex",
    "b.sty",
    "c.cls",
    "d.bib",
    "notes.md",
    "content/x/index.tex",
    "content/x/res/code/snippet.tex",
    "build/ignored.tex",
    "output/ignored.tex",
    "scripts/fixtures/ignored.tex",
]

EXPECTED = {
    "format": [
        "a.tex",
        "b.sty",
        "c.cls",
        "d.bib",
        "content/x/index.tex",
        "content/x/res/code/snippet.tex",
    ],
    "lint": [
        "a.tex",
        "content/x/index.tex",
        "content/x/res/code/snippet.tex",
    ],
    "spell": [
        "a.tex",
        "content/x/index.tex",
    ],
}


@pytest.fixture
def discovery_tree(tmp_path):
    make_files(tmp_path, *TREE_FILES)
    return tmp_path


def test_normaliza_barra_final_do_root(run_script, discovery_tree):
    # Root com barra final: o script deve remove-la (${root%/}) para nao gerar
    # padroes de exclusao com '//', que nao casariam e deixariam build/output
    # vazar para a saida.
    result = run_script(
        "find-sources", str(discovery_tree) + "/", "format", "build", "output"
    )
    assert result.returncode == 0
    found = sorted_lines(result.stdout)
    # A saida e a mesma do root sem barra: build/output continuam excluidos.
    expected = sorted(str(discovery_tree / p) for p in EXPECTED["format"])
    assert found == expected
    assert str(discovery_tree / "build" / "ignored.tex") not in found
    assert str(discovery_tree / "output" / "ignored.tex") not in found


@pytest.mark.parametrize("category", ["format", "lint", "spell"])
def test_categoria(run_script, discovery_tree, category):
    result = run_script(
        "find-sources", str(discovery_tree), category, "build", "output"
    )
    assert result.returncode == 0
    expected = sorted(str(discovery_tree / p) for p in EXPECTED[category])
    assert sorted_lines(result.stdout) == expected


def test_categoria_invalida(run_script, discovery_tree):
    result = run_script(
        "find-sources", str(discovery_tree), "naoexiste", "build", "output"
    )
    assert result.returncode == 2
    assert "Categoria invalida" in result.stderr


def test_argc_errado(run_script, discovery_tree):
    result = run_script("find-sources", str(discovery_tree), "format")
    assert result.returncode == 2
    assert "Uso:" in result.stderr


def test_saida_vazia(run_script, tmp_path):
    make_files(tmp_path, "notes.md")
    result = run_script("find-sources", str(tmp_path), "format", "build", "output")
    assert result.returncode == 0
    assert result.stdout.strip() == ""


def test_exclusao_dirigida_por_parametro(run_script, tmp_path):
    make_files(
        tmp_path,
        "a.tex",
        "custom_build/x.tex",
        "custom_out/x.tex",
        "build/x.tex",
        "output/x.tex",
    )
    result = run_script(
        "find-sources", str(tmp_path), "format", "custom_build", "custom_out"
    )
    assert result.returncode == 0
    found = sorted_lines(result.stdout)
    # Os nomes passados como parametro sao os excluidos...
    assert str(tmp_path / "custom_build" / "x.tex") not in found
    assert str(tmp_path / "custom_out" / "x.tex") not in found
    # ...e "build"/"output" NAO sao mais especiais: aparecem (prova que a
    # exclusao segue os argumentos, e nao nomes hardcoded).
    assert str(tmp_path / "build" / "x.tex") in found
    assert str(tmp_path / "output" / "x.tex") in found
    assert str(tmp_path / "a.tex") in found


def _rel_to_root(line, root):
    """Reduz uma linha da saida do find-sources ao caminho relativo ancorado em
    `root`, para comparar a descoberta independentemente da forma do caminho
    emitido (relativo, ex. './a.tex', ou absoluto)."""
    norm = line.strip().replace("\\", "/")
    if norm.startswith("./"):
        norm = norm[2:]
    if Path(norm).is_absolute():
        norm = Path(os.path.relpath(norm, str(root))).as_posix()
    return norm


@pytest.mark.parametrize("category", ["format", "lint", "spell"])
def test_root_relativo_exclui_ancorados(run_script, discovery_tree, category):
    # Como o projeto usa de fato: varredura com root '.', invocada de DENTRO da
    # arvore (cwd=root). O comportamento esperado e o mesmo do root absoluto: os
    # diretorios ancorados na raiz (build/, output/, scripts/) ficam de fora e
    # somente as fontes da categoria sao descobertas.
    result = run_script(
        "find-sources", ".", category, "build", "output", cwd=str(discovery_tree)
    )
    assert result.returncode == 0
    found = sorted(
        _rel_to_root(line, discovery_tree)
        for line in result.stdout.splitlines()
        if line.strip()
    )
    assert found == sorted(EXPECTED[category])
