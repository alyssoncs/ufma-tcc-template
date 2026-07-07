# Roda o linter LaTeX (chktex) sobre os arquivos de conteudo (.tex). Numa unica
# invocacao, para que o chktex veja todos os arquivos de uma vez.
#
# Uso: lint.ps1 <root> <build_dir> <out_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 3) {
  [Console]::Error.WriteLine("Uso: lint.ps1 <root> <build_dir> <out_dir>")
  exit 2
}
$root = $args[0]
$buildDir = $args[1]
$outDir = $args[2]

$files = @(& "$PSScriptRoot/find-sources.ps1" $root lint $buildDir $outDir)

# Sem arquivos para lintar: sai limpo (nao chama o chktex sem argumentos, o que
# o faria ler do stdin e travar).
if ($files.Count -eq 0) {
  exit 0
}

chktex -q @files
exit $LASTEXITCODE
