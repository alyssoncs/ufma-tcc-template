# Copilot Instructions

## Project Overview

This is a LaTeX template for UFMA (Universidade Federal do Maranhão) undergraduate thesis (TCC/monografia), following ABNT formatting standards. It uses the `abntex2` document class compiled with XeLaTeX via `latexmk`.

## Build Commands

- `make` — compile the PDF (output: `output/monografia.pdf`)
- `make continuous` — watch mode, recompiles on file changes
- `make clean` — remove build artifacts
- `make cleanall` — remove build artifacts and output PDF

The build uses `latexmk` configured in `.latexmkrc`. Auxiliary files go to `build/`, final PDF to `output/`.

## Architecture

- `monografia.tex` — main entry point, defines document structure and includes all parts
- `metadata.tex` — thesis metadata (title, author, date, institution, advisor)
- `macros.tex` — reusable term definitions using `\newterm` and `\foreign` commands
- `tccconfig.sty` — all package imports and their configuration (fonts, colors, code listings, hyperlinks)
- `content/` — each section is a subdirectory with an `index.tex` file
- `bib/biblio.bib` — BibTeX bibliography database

## Key Conventions

- **XeLaTeX only** — the project uses `xelatex` as the TeX engine (configured in `.latexmkrc`)
- **Content organization** — each logical section lives in `content/<section-name>/index.tex`
- **Term consistency** — recurring terms (especially foreign words and acronyms) are defined as macros in `macros.tex` using `\newterm` for reuse and consistent formatting
- **Foreign words** — use `\foreign{word}` (renders as italic) for foreign language terms
- **Citation style** — ABNT author-date style via `abntex2cite` with `alf` option
- **Code listings** — use `lstlisting` with predefined styles (`baseStyle`, `javaStyle`, `latexStyle`) from `tccconfig.sty`
- **Language** — all content and comments are written in Brazilian Portuguese

## CI/CD

GitHub Actions (`.github/workflows/ci.yaml`) builds the PDF using the `texlive/texlive:latest` container on every push to `master` and on PRs. On `master`, the compiled PDF is deployed to an orphan `pdf` branch.
