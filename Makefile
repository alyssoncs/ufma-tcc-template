.PHONY: pdf continuous format format-check lint spell check build clean cleanall

# Diretorios de saida do latexmk (devem espelhar $aux_dir/$out_dir do .latexmkrc).
BUILD_DIR := build
OUT_DIR := output

# Descobre os arquivos fonte (.tex/.sty/.cls/.bib) automaticamente (inclui arquivos novos ainda nao commitados),
# ignorando os diretorios de build/output.
FORMAT_FILES := $(shell find . \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.bib' \) -not -path './$(BUILD_DIR)/*' -not -path './$(OUT_DIR)/*')

# Arquivos .tex de conteudo para o linter (chktex). Pacotes (.sty/.cls) e a
# bibliografia (.bib) ficam de fora porque geram so ruido no ChkTeX.
LINT_FILES := $(shell find . -name '*.tex' -not -path './$(BUILD_DIR)/*' -not -path './$(OUT_DIR)/*')

# Arquivos .tex verificados pelo corretor ortografico. Os trechos de codigo
# (content/*/res/code/) ficam de fora porque sao listagens, nao prosa.
SPELL_FILES := $(shell find . -name '*.tex' -not -path './$(BUILD_DIR)/*' -not -path './$(OUT_DIR)/*' -not -path '*/res/code/*')

# Idiomas do hunspell (dicionarios do SO). pt_BR + en_US porque a monografia tem
# resumo/abstract e citacoes em ingles. Sobrescreva com 'make spell SPELL_LANG=pt_BR'.
SPELL_LANG ?= pt_BR,en_US

# Dicionario do projeto: termos tecnicos e nomes proprios validos (1 por linha).
# Para aceitar uma palavra nova, basta adiciona-la a este arquivo.
SPELL_DICT := dictionary.txt

# Alvo padrao: so compila o PDF (loop rapido de quem esta escrevendo).
pdf:
	latexmk

continuous:
	latexmk -pvc

# Formata in-place. Backups e indent.log vao para build/ (gitignored).
format:
	@for f in $(FORMAT_FILES); do latexindent -w -s -l -m -c $(BUILD_DIR)/ "$$f"; done

# So verifica (nao altera). Falha se algum arquivo precisar de formatacao.
format-check:
	@for f in $(FORMAT_FILES); do \
	  latexindent -k -s -l -m -c $(BUILD_DIR)/ "$$f" || \
	  { echo "Fora de formatacao: $$f (rode 'make format')"; exit 1; }; \
	done

lint:
	@chktex -q $(LINT_FILES)

# Corretor ortografico: roda o hunspell (modo LaTeX) por arquivo via scripts/spell.sh,
# reportando as palavras desconhecidas de todos os arquivos antes de falhar.
spell:
	@./scripts/spell.sh $(SPELL_LANG) $(SPELL_DICT) $(SPELL_FILES)

# Valida sem compilar nem alterar arquivos.
check: format-check lint spell

# Pipeline completo: valida antes de compilar (fail-fast nos checks baratos).
build: check pdf

clean:
	latexmk -c
	rm -rf $(BUILD_DIR)/

cleanall: clean
	rm -rf $(OUT_DIR)/
