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
- **Build com um comando**: `make` compila tudo e `make continuous` recompila a cada alteração no modo watch.
- **Formatação automática do código-fonte** LaTeX com `latexindent` (`make format`) — o `make format-check` ainda garante que tudo está formatado.
- **Linter integrado** com `chktex` (`make lint`) para pegar problemas comuns de LaTeX antes que virem dor de cabeça.
- **Corretor ortográfico** com `hunspell` em pt_BR e en_US (`make spell`), com dicionário de termos do projeto.
- **CI/CD pronto**: um workflow do GitHub Actions roda formatação, lint, ortografia e compilação a cada push, e publica o PDF na branch `pdf` — fácil de compartilhar.
- **Funciona local e no Overleaf**.

## Como usar

O tutorial completo, passo a passo, está [neste PDF](https://github.com/alyssoncs/ufma-tcc-template/blob/pdf/monografia.pdf) — que, aliás, é gerado por este próprio template.

Resumindo: com uma distribuição LaTeX na sua máquina, rode `make` para gerar o PDF em `output/`. Use `make continuous` para recompilar automaticamente a cada mudança e `make help` para ver todos os alvos disponíveis.

> **Nota:** o deploy do PDF só é disparado por pushes na branch `master`. Se o seu fork usa `main` como branch padrão, renomeie para `master` ou ajuste o arquivo `.github/workflows/ci.yaml`.

## FAQ

* **Existe algum TCC real escrito com esse template?**
    * Sim: https://github.com/alyssoncs/Monografia. Este template nasceu a partir dessa monografia, mas já evoluiu bastante em relação ao original.

## Dependências

Uma distribuição LaTeX moderna e completa (como o **TeX Live full**) já traz
praticamente tudo — inclusive o **Python** necessário para o `minted` e as fontes utilizadas nesse template.

<details>
<summary>Ver lista de dependências</summary>

**Para compilar o PDF:**

- **XeLaTeX** (engine fixada em `.latexmkrc`; pdfLaTeX não é suportado)
- **latexmk** e **biber**
- Classe **abntex2** e estilo **biblatex-abnt**
- Pacotes LaTeX: `biblatex`, `fontspec`, `minted`, `hyperref`, `csquotes`, `siunitx`, entre outros
- Fonte monoespaçada **Cascadia Code**
- **Python 3** + **Pygments** (usados pelo `minted`)

**Para os checks (`make check`) — opcionais:**

- **latexindent** (formatação)
- **chktex** (lint)
- **hunspell** + dicionários **pt_BR** e **en_US** (ortografia)

**Build/scripts:** `make`, `find`, `awk`, `sed`, `sort` (POSIX; já presentes em Linux/macOS).

</details>
