"""Fixtures dos testes pytest.

O pytest auto-descobre as fixtures deste arquivo. Os utilitarios puros
(constantes, `run_script`, `make_files`, `require_*`, deteccao de plataforma)
vivem em helpers.py e sao importados pelos testes diretamente.
"""

import os

import pytest

from helpers import CURRENT_PLATFORM, Platform
from helpers import run_script as _run_script


@pytest.fixture
def run_script():
    return _run_script


@pytest.fixture
def tree(tmp_path):
    """Diretorio de trabalho limpo, ja com build/ criado (equivale ao
    'TREE=...; mkdir -p "$TREE/build"' repetido nos .bats)."""
    (tmp_path / "build").mkdir()
    return tmp_path


@pytest.fixture
def latexmk_stub(tmp_path):
    """Cria um `latexmk` falso (sai 0) e devolve um env com ele no PATH.

    clean.sh roda `latexmk -c`, que num diretorio sem .tex sai com exit 10 e, sob
    'set -eu', abortaria o script antes do `rm`. O stub evita depender do latexmk
    real (equivale ao stub_latexmk do bats)."""
    bindir = tmp_path / "stubbin"
    bindir.mkdir()
    if CURRENT_PLATFORM is Platform.POSIX:
        stub = bindir / "latexmk"
        stub.write_text("#!/bin/sh\nexit 0\n")
        stub.chmod(0o755)
    else:
        raise NotImplementedError(
            "stub de latexmk ainda nao implementado (Windows)"
        )
    env = dict(os.environ)
    env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    return env
