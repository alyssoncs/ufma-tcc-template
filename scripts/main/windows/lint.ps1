# Roda o linter LaTeX (chktex) sobre os arquivos de conteudo (.tex). Numa unica
# invocacao, para que o chktex veja todos os arquivos de uma vez. O arquivo de
# configuracao e passado explicitamente ao chktex (-l), para que suas opcoes
# valham em qualquer plataforma, sem depender de o chktex auto-descobri-lo pelo
# nome/diretorio atual.
#
# Uso: lint.ps1 <root> <config> <build_dir> <out_dir>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -ne 4) {
  [Console]::Error.WriteLine("Uso: lint.ps1 <root> <config> <build_dir> <out_dir>")
  exit 2
}
$root = $args[0]
$config = $args[1]
$buildDir = $args[2]
$outDir = $args[3]

$files = @(& "$PSScriptRoot/find-sources.ps1" $root lint $buildDir $outDir)

# Sem arquivos para lintar: sai limpo (nao chama o chktex sem argumentos, o que
# o faria ler do stdin e travar).
if ($files.Count -eq 0) {
  exit 0
}

chktex -q -l $config @files
exit $LASTEXITCODE
