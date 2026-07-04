"""Porta format.bats: o format.sh reescreve os fontes in-place (deixando-os
formatados) e roteia backups/log do latexindent para build/, sem sujar o
diretorio do fonte.
"""

from helpers import copy_fixture, require_latexindent


def test_round_trip(run_script, tree):
    require_latexindent()
    # Copia (nao referencia) o fixture: format reescreve in-place e a descoberta
    # exige o arquivo dentro da arvore.
    bad = tree / "bad.tex"
    copy_fixture("format/unformatted.tex", bad)
    before = bad.read_text()

    result = run_script("format", str(tree), "build", "output")
    assert result.returncode == 0

    # O arquivo mudou (foi reformatado)...
    assert bad.read_text() != before

    # ...e agora esta formatado segundo o proprio format-check.
    check = run_script("format-check", str(tree), "build", "output")
    assert check.returncode == 0


def test_backups_vao_para_build(run_script, tree):
    require_latexindent()
    copy_fixture("format/unformatted.tex", tree / "bad.tex")

    result = run_script("format", str(tree), "build", "output")
    assert result.returncode == 0

    # Nenhum backup do latexindent ao lado do fonte.
    assert list(tree.glob("*.bak*")) == []
    # O backup e/ou o indent.log foram para build/.
    assert list((tree / "build").iterdir()) != []
