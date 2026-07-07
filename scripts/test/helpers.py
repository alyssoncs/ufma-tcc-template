"""Utilitarios compartilhados dos testes pytest.

Expoe a deteccao de plataforma (`CURRENT_PLATFORM`), o invocador de scripts
`run_script` (independente de plataforma: no unix roda o `.sh` via `sh`; no
Windows rodara o `.ps1` via `pwsh` quando esses scripts existirem), e helpers
puros de montagem de arvore e de exigencia de toolchain. As fixtures ficam em
conftest.py; aqui vivem apenas funcoes reutilizaveis sem estado de teste.
"""

import os
import shutil
import subprocess
from enum import Enum
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
MAIN = REPO_ROOT / "scripts" / "main"
POSIX_MAIN = MAIN / "posix"
WINDOWS_MAIN = MAIN / "windows"
FIXTURES = REPO_ROOT / "scripts" / "fixtures"


class Platform(Enum):
    POSIX = "posix"
    WINDOWS = "windows"


def _detect_platform():
    if os.name == "posix":
        return Platform.POSIX
    if os.name == "nt":
        return Platform.WINDOWS
    raise NotImplementedError(f"plataforma nao suportada: {os.name}")


CURRENT_PLATFORM = _detect_platform()


def _script_command(name, args):
    if CURRENT_PLATFORM is Platform.POSIX:
        return ["sh", str(POSIX_MAIN / f"{name}.sh"), *args]
    raise NotImplementedError(
        "invocacao de scripts .ps1 ainda nao implementada (Windows)"
    )


def run_script(name, *args, cwd=None, env=None):
    """Invoca um script de scripts/main pelo nome logico (ex.: "format") e
    devolve o `subprocess.CompletedProcess` (returncode/stdout/stderr)."""
    return subprocess.run(
        _script_command(name, args),
        capture_output=True,
        text=True,
        cwd=cwd,
        env=env,
    )


def make_files(base, *relpaths):
    """Cria arquivos vazios (e os diretorios pais) em `base`."""
    for rel in relpaths:
        path = Path(base) / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch()


def sorted_lines(text):
    """Linhas nao-vazias, ordenadas: comparacao estavel da saida do find."""
    return sorted(line for line in text.splitlines() if line.strip())


def copy_fixture(src_rel, dst):
    """Copia uma fixture de scripts/fixtures para `dst`."""
    shutil.copy(FIXTURES / src_rel, dst)


def require_latexindent():
    if shutil.which("latexindent") is None:
        pytest.fail("latexindent nao instalado")


def require_chktex():
    if shutil.which("chktex") is None:
        pytest.fail("chktex nao instalado")


def require_hunspell():
    if shutil.which("hunspell") is None:
        pytest.fail("hunspell nao instalado")
    result = subprocess.run(["hunspell", "-D"], capture_output=True, text=True)
    listing = result.stdout + result.stderr
    if "/pt_BR" not in listing:
        pytest.fail("dicionario pt_BR ausente")
    if "/en_US" not in listing:
        pytest.fail("dicionario en_US ausente")
