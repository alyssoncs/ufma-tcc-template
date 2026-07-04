"""Cada script de scripts/main rejeita uso incorreto (sem
argumentos) com exit 2 e mensagem de uso no stderr. Cobre o contrato de CLI
compartilhado por todos os scripts.
"""

import pytest


@pytest.mark.parametrize(
    "script",
    [
        "format",
        "format-check",
        "lint",
        "clean",
        "cleanall",
        "find-sources",
        "spell",
    ],
)
def test_sem_args_sai_com_2(run_script, script):
    result = run_script(script)
    assert result.returncode == 2


@pytest.mark.parametrize(
    "script",
    [
        "format",
        "format-check",
        "lint",
        "clean",
        "cleanall",
        "find-sources",
        "spell",
    ],
)
def test_sem_args_mostra_uso(run_script, script):
    result = run_script(script)
    assert "Uso:" in result.stderr
