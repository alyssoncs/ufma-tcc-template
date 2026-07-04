"""lint.sh roda o chktex (exit 0 num .tex limpo, falha quando
acha um problema) e passa TODOS os arquivos numa unica invocacao (o script monta
os parametros posicionais a partir da descoberta).

A arvore e hermetica (sem .chktexrc) -> chktex usa os defaults. Usamos o aviso
W26 (espaco antes de pontuacao), estavel entre versoes do chktex.
"""

from helpers import copy_fixture, make_files, require_chktex


def test_sem_fontes_sai_limpo(run_script, tree):
    require_chktex()
    # Arvore sem nenhum .tex: nada a lintar. O script deve sair 0 SEM chamar o
    # chktex (evita o WARNING de abrir '' e o risco de travar lendo stdin).
    make_files(tree, "notes.md")

    result = run_script("lint", str(tree), "build", "output")
    assert result.returncode == 0
    assert "WARNING" not in result.stderr


def test_tex_limpo_passa(run_script, tree):
    require_chktex()
    copy_fixture("lint/clean.tex", tree / "clean.tex")

    result = run_script("lint", str(tree), "build", "output")
    assert result.returncode == 0


def test_warning_falha_e_cita_arquivo(run_script, tree):
    require_chktex()
    copy_fixture("lint/warning.tex", tree / "warn.tex")

    result = run_script("lint", str(tree), "build", "output")
    assert result.returncode != 0
    assert "warn.tex" in result.stdout


def test_passa_todos_numa_invocacao(run_script, tree):
    require_chktex()
    copy_fixture("lint/warning.tex", tree / "a.tex")
    copy_fixture("lint/warning.tex", tree / "b.tex")

    result = run_script("lint", str(tree), "build", "output")
    assert result.returncode != 0
    # A saida menciona AMBOS os arquivos: prova que o loop montou os parametros
    # posicionais e passou tudo de uma vez ao chktex.
    assert "a.tex" in result.stdout
    assert "b.tex" in result.stdout
