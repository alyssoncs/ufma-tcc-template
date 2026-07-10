"""lint roda o chktex sobre os arquivos de conteudo (.tex).

Contrato exercitado aqui:

- Assinatura: `lint <root> <config> <build_dir> <out_dir>`. O caminho do arquivo
  de configuracao do chktex e um argumento OBRIGATORIO, logo APOS o root.
- O script repassa esse config ao chktex, de modo que as opcoes do arquivo
  (inclusive supressoes de aviso) valham na analise --- em qualquer plataforma,
  sem depender de o chktex auto-descobrir o config pelo nome/diretorio atual.

A arvore de trabalho e hermetica (sem config nela) e os arquivos de config vivem
em scripts/fixtures/lint/ (FORA da arvore e do CWD). Assim, a unica maneira de a
supressao de aviso surtir efeito e o script passar o config explicitamente ao
chktex. Usamos o aviso W26 (espaco antes de pontuacao), estavel entre versoes.
"""

from helpers import FIXTURES, copy_fixture, make_files, require_chktex

SUPPRESS_RC = FIXTURES / "lint" / "suppress.chktexrc"
NEUTRAL_RC = FIXTURES / "lint" / "neutral.chktexrc"


def test_config_e_obrigatorio_apos_root(run_script, tree):
    require_chktex()
    # Invocacao sem o argumento de config (apenas root/build/out) e um erro de
    # uso: o config e obrigatorio. Sai 2 (uso), nao 0 nem falha de lint.
    result = run_script("lint", str(tree), "build", "output", cwd=str(tree))
    assert result.returncode == 2


def test_config_suprime_avisos(run_script, tree):
    require_chktex()
    # .tex que dispara o W26 + config que suprime o W26. Como o config esta fora
    # da arvore/CWD, o chktex so o aplica se o script o repassar. Se o script
    # ignorar o config, o W26 dispara e o teste falha.
    copy_fixture("lint/warning.tex", tree / "warn.tex")

    result = run_script(
        "lint", str(tree), str(SUPPRESS_RC), "build", "output", cwd=str(tree)
    )
    assert result.returncode == 0
    assert "warn.tex" not in result.stdout


def test_config_neutro_nao_suprime(run_script, tree):
    require_chktex()
    # Controle: mesmo .tex, mas com um config que NAO suprime o W26. O aviso deve
    # disparar e citar o arquivo. Prova que a supressao do teste acima veio do
    # conteudo do config, e nao de o script engolir a saida/exit do chktex.
    copy_fixture("lint/warning.tex", tree / "warn.tex")

    result = run_script(
        "lint", str(tree), str(NEUTRAL_RC), "build", "output", cwd=str(tree)
    )
    assert result.returncode != 0
    assert "warn.tex" in result.stdout


def test_sem_fontes_sai_limpo(run_script, tree):
    require_chktex()
    # Arvore sem nenhum .tex: nada a lintar. O script deve sair 0 SEM chamar o
    # chktex (evita o WARNING de abrir '' e o risco de travar lendo stdin).
    make_files(tree, "notes.md")

    result = run_script(
        "lint", str(tree), str(NEUTRAL_RC), "build", "output", cwd=str(tree)
    )
    assert result.returncode == 0
    assert "WARNING" not in result.stderr


def test_tex_limpo_passa(run_script, tree):
    require_chktex()
    copy_fixture("lint/clean.tex", tree / "clean.tex")

    result = run_script(
        "lint", str(tree), str(NEUTRAL_RC), "build", "output", cwd=str(tree)
    )
    assert result.returncode == 0


def test_passa_todos_numa_invocacao(run_script, tree):
    require_chktex()
    copy_fixture("lint/warning.tex", tree / "a.tex")
    copy_fixture("lint/warning.tex", tree / "b.tex")

    result = run_script(
        "lint", str(tree), str(NEUTRAL_RC), "build", "output", cwd=str(tree)
    )
    assert result.returncode != 0
    # A saida menciona AMBOS os arquivos: prova que o loop montou os parametros
    # posicionais e passou tudo de uma vez ao chktex.
    assert "a.tex" in result.stdout
    assert "b.tex" in result.stdout
