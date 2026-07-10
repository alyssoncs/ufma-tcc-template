# Ambiente Docker do template: toolchain completo para rodar `just` de dentro do
# container. Base `texlive/texlive:latest` — ja traz TeX Live completo,
# `latexindent` e `chktex`; aqui instalamos por cima o restante do toolchain.
#
# Pinning `:latest` (rolling, sem digest): LaTeX e retrocompativel.
FROM texlive/texlive:latest

# - just: orquestrador dos workflows do template.
# - hunspell + dicts pt_BR/en_US: spellcheck (`just spell`). No Debian os dicts
#   ficam em /usr/share/hunspell e sao achados sem DICPATH.
# - python3 + pip: suite pytest dos scripts (`just test`).
# - shellcheck: analise estatica dos scripts POSIX (`just test`).
# `just` nao esta nos repositorios do Debian estavel, entao usamos o instalador
# oficial para /usr/local/bin.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        hunspell \
        hunspell-pt-br \
        hunspell-en-us \
        python3 \
        python3-pip \
        shellcheck \
        curl \
    && curl --proto '=https' --tlsv1.2 -fsSL https://just.systems/install.sh \
        | bash -s -- --to /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

# Deps da suite pytest (instaladas na imagem para `just test` rodar offline).
# --break-system-packages: o Python do Debian e "externally managed"; instalar
# no ambiente global e o esperado dentro do container.
COPY scripts/test/requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --break-system-packages --no-cache-dir \
        -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# O container roda com o UID/GID do host (definido no docker-compose.yml), que
# normalmente nao tem entrada no /etc/passwd da imagem e, portanto, sem HOME
# gravavel. O cache do minted/Pygments e do TeX Live precisa de um HOME que
# possa escrever; /tmp e world-writable e resolve isso para qualquer UID.
ENV HOME=/tmp

WORKDIR /work
