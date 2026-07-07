# Descoberta de arquivos fonte do projeto. Imprime, um por linha, os arquivos de
# uma dada categoria, ignorando os diretorios de build/output (e, no caso da
# ortografia, as listagens de codigo). Inclui arquivos novos ainda nao commitados.
#
# Centraliza a descoberta para que os scripts de format/lint/spell compartilhem a
# mesma logica.
#
# A varredura parte de <root>; build_dir/out_dir sao interpretados relativos a
# ela. O diretorio scripts/ fica de fora de todas as categorias.
#
# Uso: find-sources.ps1 <root> <categoria> <build_dir> <out_dir>
#   root      diretorio raiz da varredura (ex.: '.')
#   categoria format|lint|spell
#   format    arquivos fonte para o latexindent (.tex, .sty, .cls, .bib)
#   lint      arquivos .tex para o chktex
#   spell     arquivos .tex para o hunspell (exclui as listagens em */res/code/)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 4) {
  [Console]::Error.WriteLine("Uso: find-sources.ps1 <root> <format|lint|spell> <build_dir> <out_dir>")
  exit 2
}

$root = $args[0]
$category = $args[1]
$buildDir = $args[2]
$outDir = $args[3]

if ($category -notin @('format', 'lint', 'spell')) {
  [Console]::Error.WriteLine("Categoria invalida: $category (use format, lint ou spell)")
  exit 2
}

# Remove uma eventual barra final para nao gerar '//' nos caminhos de saida.
$rootTrim = $root.TrimEnd([char]47, [char]92)

# .tex para todas as categorias; format inclui tambem .sty/.cls/.bib.
$extensions = if ($category -eq 'format') {
  @('.tex', '.sty', '.cls', '.bib')
} else {
  @('.tex')
}

Get-ChildItem -Path $rootTrim -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $extensions -contains $_.Extension } |
  ForEach-Object {
    $full = $_.FullName
    $rel = $full.Substring($rootTrim.Length + 1).Replace([char]92, [char]47)

    # Exclusoes ancoradas na raiz: build_dir/, out_dir/ e scripts/.
    if ($rel -like "$buildDir/*") { return }
    if ($rel -like "$outDir/*") { return }
    if ($rel -like 'scripts/*') { return }

    # Ortografia: exclui as listagens de codigo (*/res/code/*), que sao codigo.
    if ($category -eq 'spell' -and $rel -like '*/res/code/*') { return }

    $full
  }

