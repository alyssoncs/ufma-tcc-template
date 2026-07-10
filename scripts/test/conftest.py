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
    """Diretorio de trabalho limpo, ja com build/ criado."""
    (tmp_path / "build").mkdir()
    return tmp_path


@pytest.fixture
def latexmk_stub(tmp_path):
    """Cria um `latexmk` falso (sai 0) e devolve um env com ele no PATH.

    clean.sh roda `latexmk -c`, que num diretorio sem .tex sai com exit 10 e, sob
    'set -eu', abortaria o script antes do `rm`. O stub evita depender do latexmk
    real."""
    bindir = tmp_path / "stubbin"
    bindir.mkdir()
    if CURRENT_PLATFORM is Platform.POSIX:
        stub = bindir / "latexmk"
        stub.write_text("#!/bin/sh\nexit 0\n")
        stub.chmod(0o755)
    else:
        # No Windows o PATH resolve latexmk.cmd (via PATHEXT); um .sh nao seria
        # executavel. O .cmd sai 0 como o stub POSIX.
        stub = bindir / "latexmk.cmd"
        stub.write_text("@echo off\r\nexit /b 0\r\n")
    env = dict(os.environ)
    env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    return env


@pytest.fixture
def latexmk_spy(tmp_path):
    """Como o latexmk_stub, mas REGISTRA os argumentos de cada invocacao.

    O stub anexa `"$@"` (uma invocacao por linha) a um arquivo de log e sai 0.
    Devolve `(env, logpath)`: o env com o stub no PATH e o caminho do log, para
    o teste provar que o script realmente chamou `latexmk` (e com quais args)."""
    bindir = tmp_path / "spybin"
    bindir.mkdir()
    logpath = tmp_path / "latexmk-calls.log"
    if CURRENT_PLATFORM is Platform.POSIX:
        stub = bindir / "latexmk"
        stub.write_text(f'#!/bin/sh\necho "$@" >>"{logpath}"\nexit 0\n')
        stub.chmod(0o755)
    else:
        # Analogo Windows: latexmk.cmd registra os argumentos (%*) no log e sai 0.
        stub = bindir / "latexmk.cmd"
        stub.write_text(f'@echo off\r\necho %*>>"{logpath}"\r\nexit /b 0\r\n')
    env = dict(os.environ)
    env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    return env, logpath
