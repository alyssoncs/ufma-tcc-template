"""Testes-prova do setup do harness: mostram que da para invocar um script de
`scripts/main` e fazer assert tanto no exit code quanto na saida (stderr).
Nao portam a suite bats --- servem so para validar a base do pytest.
"""


def test_format_sem_args_sai_com_2(run_script):
    result = run_script("format")
    assert result.returncode == 2


def test_format_sem_args_mostra_uso(run_script):
    result = run_script("format")
    assert "Uso:" in result.stderr
