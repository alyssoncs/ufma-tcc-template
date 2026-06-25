.PHONY: pdf continuous format format-check lint check build clean cleanall

# Descobre os arquivos fonte (.tex/.sty/.cls/.bib) automaticamente (inclui arquivos novos ainda nao commitados),
# ignorando os diretorios de build/output.
FORMAT_FILES := $(shell find . \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.bib' \) -not -path './build/*' -not -path './output/*')

# Arquivos .tex de conteudo para o linter (chktex). Pacotes (.sty/.cls) e a
# bibliografia (.bib) ficam de fora porque geram so ruido no ChkTeX.
LINT_FILES := $(shell find . -name '*.tex' -not -path './build/*' -not -path './output/*')

# Alvo padrao: so compila o PDF (loop rapido de quem esta escrevendo).
pdf:
	latexmk

continuous:
	latexmk -pvc

# Formata in-place. Backups e indent.log vao para build/ (gitignored).
format:
	@for f in $(FORMAT_FILES); do latexindent -w -s -l -m -c build/ "$$f"; done

# So verifica (nao altera). Falha se algum arquivo precisar de formatacao.
format-check:
	@for f in $(FORMAT_FILES); do \
	  latexindent -k -s -l -m -c build/ "$$f" || \
	  { echo "Fora de formatacao: $$f (rode 'make format')"; exit 1; }; \
	done

lint:
	@chktex -q $(LINT_FILES)

# Valida sem compilar nem alterar arquivos.
check: format-check lint

# Pipeline completo: valida antes de compilar (fail-fast nos checks baratos).
build: check pdf

clean:
	latexmk -c
	rm -rf build/

cleanall: clean
	rm -rf output/
