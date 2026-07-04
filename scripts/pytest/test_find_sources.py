"""Porta find-sources.bats: descoberta de arquivos por categoria
(format/lint/spell), exclusao de build/output/scripts e das listagens em
*/res/code/*, e validacao de categoria/uso. A arvore de teste e montada num
diretorio temporario (nao depende da arvore real do repo).
"""

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
