"""Porta format-check.bats: falha (exit 1) quando ha arquivo desformatado, passa
(exit 0) apos formatar (round-trip) e roteia a mensagem de erro para o stderr.

Round-trip (formatar com o proprio script e entao checar) evita depender de um
golden "formatado", que e fragil entre latexindent 3.x e 4.x.
"""

from helpers import copy_fixture, require_latexindent


def test_falha_em_desformatado(run_script, tree):
    require_latexindent()
    copy_fixture("format/unformatted.tex", tree / "bad.tex")

    result = run_script("format-check", str(tree), "build", "output")
    assert result.returncode == 1
    assert "Fora de formatacao" in result.stderr


def test_passa_apos_format(run_script, tree):
    require_latexindent()
    copy_fixture("format/unformatted.tex", tree / "bad.tex")

    fmt = run_script("format", str(tree), "build", "output")
    assert fmt.returncode == 0

    result = run_script("format-check", str(tree), "build", "output")
    assert result.returncode == 0
    assert result.stdout == ""


def test_erro_no_stderr(run_script, tree):
    require_latexindent()
    copy_fixture("format/unformatted.tex", tree / "bad.tex")

    result = run_script("format-check", str(tree), "build", "output")
    assert result.returncode == 1
    # stdout limpo; a mensagem fica no stderr (contrato importante para o port).
    assert result.stdout == ""
    assert "Fora de formatacao" in result.stderr


def test_para_no_primeiro_desformatado(run_script, tree):
    require_latexindent()
    # Dois arquivos desformatados: o script deve sair no PRIMEIRO, sem checar o
    # segundo (short-circuit). Observavel pela contagem de mensagens de erro.
    copy_fixture("format/unformatted.tex", tree / "a.tex")
    copy_fixture("format/unformatted.tex", tree / "b.tex")

    result = run_script("format-check", str(tree), "build", "output")
    assert result.returncode == 1
    assert result.stderr.count("Fora de formatacao") == 1
