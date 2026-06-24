.PHONY: all continuous format format-check clean cleanall

# Descobre os arquivos fonte (.tex/.sty/.cls/.bib) automaticamente (inclui arquivos novos ainda nao commitados),
# ignorando os diretorios de build/output.
FORMAT_FILES := $(shell find . \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.bib' \) -not -path './build/*' -not -path './output/*')

all:
	latexmk

continuous:
	latexmk -pvc

# Formata in-place. Backups e indent.log vao para build/ (gitignored).
format:
	@for f in $(FORMAT_FILES); do latexindent -w -s -l -c build/ "$$f"; done

# So verifica (nao altera). Falha se algum arquivo precisar de formatacao.
format-check:
	@for f in $(FORMAT_FILES); do \
	  latexindent -k -s -l -c build/ "$$f" || \
	  { echo "Fora de formatacao: $$f (rode 'make format')"; exit 1; }; \
	done

clean:
	latexmk -c
	rm -rf build/

cleanall: clean
	latexmk -C
	rm -rf build/
	rm -rf output/
