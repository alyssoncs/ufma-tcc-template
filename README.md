# Template de TCC da UFMA em LaTeX

Template de TCC/monografia da Universidade Federal do Maranhão em LaTeX, pronto pra usar e já seguindo as normas ABNT.

Esqueça as brigas com margens, numeração de páginas, sumário, citações e referências. A formatação já está resolvida — você foca no que importa: escrever o seu trabalho. Faça uma cópia, troque o conteúdo pelo seu e compile.

## O que já vem pronto

- **Formatação ABNT** resolvida pelo LaTeX — você escreve o conteúdo, o resto se ajeita.
- **Estrutura pré-textual completa**: capa, folha de aprovação, ficha catalográfica, resumo, abstract, agradecimentos, epígrafe e sumário.
- **Código organizado e modular**: nada de um único arquivo `.tex` gigante. Cada seção fica no seu próprio diretório em `content/`, com imagens e snippets de código ao lado do texto que os usa. Adicionar um capítulo é criar uma pasta e um `\input`.
- **`abntex2` + XeLaTeX já configurados**, com fontes via `fontspec` e fonte monoespaçada Cascadia Code.
- **Bibliografia ABNT** com `biblatex` + `biber` (`style=abnt`): basta citar com `\cite` / `\textcite` e referenciar a entrada `.bib`.
- **Unidades e números consistentes** com `siunitx` — números, unidades de medida e intervalos formatados do jeito certo, sem você se preocupar com espaçamento ou notação.
- **Listagens de código** com syntax highlighting via `minted`/Pygments.
- **Macros utilitárias** (`\newterm`, `\foreign`) para manter termos e estrangeirismos consistentes ao longo do texto.
- **Build com um comando**: `just` compila tudo e `just continuous` recompila a cada alteração no modo watch.
- **Formatação automática do código-fonte** LaTeX com `latexindent` (`just format`) — o `just format-check` ainda garante que tudo está formatado.
- **Linter integrado** com `chktex` (`just lint`) para pegar problemas comuns de LaTeX antes que virem dor de cabeça.
- **Corretor ortográfico** com `hunspell` em pt_BR e en_US (`just spell`), com dicionário de termos do projeto.
- **CI/CD pronto**: um workflow do GitHub Actions roda formatação, lint, ortografia e compilação a cada push, e publica o PDF na branch `pdf` — fácil de compartilhar.
- **Funciona local e no Overleaf**.

## Setup

Para editar e compilar o template você precisa de um ambiente com o toolchain (uma distribuição LaTeX, o `just` e as ferramentas de checagem). Há **5 caminhos de setup** suportados: **Docker**, **Nix** e os três nativos — **Linux**, **macOS** e **Windows**. Docker e Nix entregam um ambiente reprodutível (o mesmo toolchain da CI, sem você caçar dependência); os nativos rodam direto na sua máquina, ao custo de você instalar e resolver o toolchain por conta própria.

Seja qual for o ambiente, o dia a dia é sempre o mesmo: você roda o [`just`](https://github.com/casey/just) por cima dele. `just` (ou `just pdf`) gera o PDF em `output/`, `just continuous` recompila a cada mudança (modo watch) e `just help` lista todas as recipes.

### Docker

Com o [Docker](https://docs.docker.com/get-docker/) instalado, o toolchain completo já vem montado numa imagem — você trabalha de dentro do container:

```sh
docker compose run --rm tcc bash   # entra no ambiente
just                               # compila (ou just continuous, just help...)
```

Ou sem shell interativo, rodando a recipe direto:

```sh
docker compose run --rm tcc just
```

Limitações:

- **Permissões (UID/GID):** no Linux, os arquivos gerados em `build/` e `output/` sairiam como `root`. Exporte seu UID/GID antes para o dono ficar correto:

  ```sh
  UID=$(id -u) GID=$(id -g) docker compose run --rm tcc just
  ```

  Sem isso, cai no fallback `1000:1000`.
- **Windows/PowerShell:** o `id -u`/`id -g` é sintaxe unix; no Windows o comando de entrada difere (e o problema de dono não se aplica da mesma forma).
- **Tamanho:** a imagem parte do `texlive/texlive:latest` (TeX Live completo), então o primeiro download/build é pesado.

### Nix

Com o [Nix](https://nixos.org/download/) instalado, o flake provê um `devShell` com o toolchain completo (o mesmo da CI, fixado pelo `flake.lock`):

```sh
nix develop           # entra no devShell
just                  # compila (ou just continuous, just help...)
```

Ou rodando a recipe direto, sem entrar no shell:

```sh
nix develop -c just
```

Há também um **build hermético** do PDF, isolado numa sandbox sem rede:

```sh
nix build             # gera o PDF em ./result/monografia.pdf
```

Limitações:

- **Flakes é experimental:** habilite `nix-command` e `flakes` (via `~/.config/nix/nix.conf` ou a flag `--experimental-features 'nix-command flakes'`).
- **Windows:** Nix roda nativo só em Linux/macOS; no Windows, use via **WSL2**.
- **Tamanho:** o `texliveFull` é grande, então o primeiro download/realização do devShell é pesado.

### Nativo (Linux / macOS / Windows)

Aqui você instala o toolchain direto na sua máquina. Como não há como controlar o setup de cada sistema, este caminho é **um apanhado de alto nível** — não um tutorial garantido. Você resolve os pepinos da sua própria máquina.

Em alto nível, você vai precisar de:

- Uma distribuição **LaTeX moderna e completa** (como o **TeX Live full**), que já traz XeLaTeX, `latexmk`, `biber`, a classe `abntex2`, o `biblatex-abnt`, o **Python + Pygments** do `minted` e a fonte **Cascadia Code**.
- O [`just`](https://github.com/casey/just) (não vem com o sistema).
- Para os checks opcionais (`just check`): **latexindent**, **chktex** e **hunspell** com os dicionários **pt_BR** e **en_US**.

<details>
<summary>Ver lista completa de dependências</summary>

**Para compilar o PDF:**

- **XeLaTeX** (engine fixada em `.latexmkrc`; pdfLaTeX não é suportado)
- **latexmk** e **biber**
- Classe **abntex2** e estilo **biblatex-abnt**
- Pacotes LaTeX: `biblatex`, `fontspec`, `minted`, `hyperref`, `csquotes`, `siunitx`, entre outros
- Fonte monoespaçada **Cascadia Code**
- **Python 3** + **Pygments** (usados pelo `minted`) — o Python já vem com o **TeX Live full**

**Para os checks (`just check`) — opcionais:**

- **latexindent** (formatação)
- **chktex** (lint)
- **hunspell** + dicionários **pt_BR** e **en_US** (ortografia)

**Orquestração:** [**just**](https://github.com/casey/just) (executor de comandos; não vem com o sistema, precisa ser instalado).

**Build/scripts:** `find`, `awk`, `sed`, `sort` (POSIX; já presentes em Linux/macOS).

</details>

Para os **comandos exatos** de instalação por SO, a melhor referência é o próprio workflow da CI: [`.github/workflows/build.yaml`](.github/workflows/build.yaml) instala e roda esse toolchain nos três sistemas (pacotes, dicionários do hunspell, deps Perl do `latexindent` etc.) — é a fonte executável de verdade, sempre atualizada.

## Como usar o template

Com o ambiente pronto, é hora de trocar o conteúdo de exemplo pelo seu. O guia completo está no **próprio PDF do template** — [`monografia.pdf`](https://github.com/alyssoncs/ufma-tcc-template/blob/pdf/monografia.pdf), gerado por este repositório —, que funciona como um exemplo vivo: ele mostra, passo a passo, como preencher os metadados, organizar cada seção em `content/`, usar as macros (`\newterm`, `\foreign`), inserir citações e referências ABNT e formatar listagens de código.

## CI/CD

O GitHub Actions roda **os mesmos checks do `just check`** — formatação (`format-check`), lint (`chktex`), ortografia (`hunspell`) e os testes dos scripts — e compila o PDF a cada push e PR; qualquer pendência **quebra o build**. Ao final, publica o PDF na branch `pdf` — fácil de compartilhar.

Os caminhos que a CI exercita **mudam entre o repositório upstream e os forks**:

- **No upstream** (variável de repositório `IS_TEMPLATE_REPO = true`): roda a matriz completa — nativo nos três SOs (Linux, macOS, Windows), **Docker** e **Nix** —, garantindo que todos os caminhos de setup continuam funcionando. Um workflow agendado só dispara nesse cenário.
- **Nos forks** (sem `IS_TEMPLATE_REPO`): o caminho único é o **Docker**, que é reprodutível e não depende do toolchain do runner. É também a fonte do PDF publicado na branch `pdf`.

O deploy do PDF só é disparado por pushes na branch `master`. Se o seu fork usa `main` como branch padrão, renomeie para `master` ou ajuste o arquivo `.github/workflows/ci.yaml`.

## FAQ

* **Existe algum TCC real escrito com esse template?**
    * Sim: https://github.com/alyssoncs/Monografia. Este template nasceu a partir dessa monografia, mas já evoluiu bastante em relação ao original.
