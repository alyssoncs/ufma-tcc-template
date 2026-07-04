"""Cola comum dos testes pytest.

Expoe o utilitario `run_script`, que invoca um script de `scripts/main` de forma
independente de plataforma: no unix roda o `.sh` (via `sh`); no Windows rodara o
`.ps1` (via `pwsh`) quando esses scripts existirem. Os testes chamam sempre pelo
nome logico (ex.: "format") e recebem um `subprocess.CompletedProcess`.
"""

import os
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
MAIN = REPO_ROOT / "scripts" / "main"


def _script_command(name, args):
    if os.name == "posix":
        return ["sh", str(MAIN / f"{name}.sh"), *args]
    raise NotImplementedError(
        f"invocacao de scripts nao suportada nesta plataforma: {os.name}"
    )


def _run_script(name, *args):
    return subprocess.run(_script_command(name, args), capture_output=True, text=True)


@pytest.fixture
def run_script():
    return _run_script
