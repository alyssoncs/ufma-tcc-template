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


def _script_impl():
    """Implementacao a exercitar: 'ps1' forca os .ps1 via pwsh em qualquer SO
    (andaime para validar o porte na CI unix, removido pela #65); vazio segue a
    plataforma atual."""
    return os.environ.get("SCRIPT_IMPL", "").strip().lower()


def _script_command(name, args):
    impl = _script_impl()
    if impl == "ps1" or (impl == "" and CURRENT_PLATFORM is Platform.WINDOWS):
        return ["pwsh", "-NoProfile", "-File", str(WINDOWS_MAIN / f"{name}.ps1"), *args]
    if impl in ("", "sh") and CURRENT_PLATFORM is Platform.POSIX:
        return ["sh", str(POSIX_MAIN / f"{name}.sh"), *args]
    raise NotImplementedError(
        f"combinacao nao suportada: SCRIPT_IMPL={impl!r}, plataforma={CURRENT_PLATFORM}"
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


# Palavras muito comuns em cada idioma, usadas como sonda de carregamento do
# dicionario: se o dict carregou com conteudo, o hunspell nao pode reporta-las
# como desconhecidas.
_HUNSPELL_PROBES = {"pt_BR": "casa", "en_US": "house"}


def require_hunspell():
    if shutil.which("hunspell") is None:
        pytest.fail("hunspell nao instalado")
    # Exercita o carregamento REAL de cada dicionario, um idioma por vez (o
    # caminho `-d` que o spell.sh usa), em vez de raspar o relatorio de
    # `hunspell -D` (nao-portavel: no Windows nao lista os dicts do DICPATH).
    # Verificar por idioma e obrigatorio: `-d pt_BR,en_US` sai com sucesso mesmo
    # se um dos dois faltar, mascarando a ausencia parcial.
    for lang, word in _HUNSPELL_PROBES.items():
        result = subprocess.run(
            ["hunspell", "-d", lang, "-l"],
            input=word + "\n",
            capture_output=True,
            text=True,
        )
        # Dict ausente: exit != 0 (hunspell imprime "Can't open affix or
        # dictionary files"). Dict carregado mas vazio/corrompido: a palavra
        # conhecida apareceria na lista de desconhecidas (stdout).
        if result.returncode != 0 or word in result.stdout.split():
            pytest.fail(f"dicionario {lang} ausente")
